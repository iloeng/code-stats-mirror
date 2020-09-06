defmodule CodeStatsWeb.MachineController do
  use CodeStatsWeb, :controller

  import Ecto.Query, only: [from: 2]
  alias Ecto.Changeset

  alias CodeStatsWeb.AuthUtils
  alias CodeStatsWeb.ControllerUtils
  alias CodeStats.Repo
  alias CodeStats.User.Machine
  alias CodeStats.User.CacheUtils

  @spec list(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list(conn, _params) do
    {conn, _} = common_assigns(conn)
    changeset = Machine.create_changeset()

    conn
    |> render("machines.html", changeset: changeset)
  end

  @doc """
  Action for creating a new machine.
  """
  @spec add(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def add(conn, params)

  def add(conn, %{"machine" => %{"name" => name}}) do
    {conn, user} = common_assigns(conn)

    Machine.create_changeset(%{name: name, user: user})
    |> create_machine()
    |> case do
      %Machine{} ->
        conn
        |> put_flash(:success, "Machine added successfully.")
        |> redirect(to: Routes.machine_path(conn, :list))

      %Changeset{} = changeset ->
        conn
        |> put_flash(:error, "Error adding machine.")
        |> render("machines.html", changeset: changeset)
    end
  end

  def add(conn, _params) do
    conn
    |> put_flash(:error, "Error adding machine.")
    |> list(%{})
  end

  @spec view_single(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def view_single(conn, %{"id" => id}) do
    user = AuthUtils.get_current_user(conn)

    with %Machine{} = machine <- get_machine_or_404(conn, user, id),
         changeset = Machine.update_changeset(machine) do
      conn
      |> single_machine_assigns(machine)
      |> render("single_machine.html", changeset: changeset)
    end
  end

  @spec edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def edit(conn, %{"id" => id, "machine" => params}) do
    user = AuthUtils.get_current_user(conn)

    with %Machine{} = machine <- get_machine_or_404(conn, user, id) do
      with changeset = Machine.update_changeset(machine, params),
           {:ok, machine} <- Repo.update(changeset) do
        conn
        |> single_machine_assigns(machine)
        |> put_flash(:success, "Machine edited successfully.")
        |> redirect(to: Routes.machine_path(conn, :view_single, machine.id))
      else
        {:error, changeset} ->
          conn
          |> single_machine_assigns(machine)
          |> put_status(500)
          |> put_flash(:error, "Error editing machine.")
          |> render("single_machine.html", changeset: changeset)
      end
    end
  end

  @spec regen_machine_key(Plug.Conn.t(), map()) :: any()
  def regen_machine_key(conn, %{"id" => id}) do
    user = AuthUtils.get_current_user(conn)

    with %Machine{} = machine <- get_machine_or_404(conn, user, id),
         changeset = Machine.api_changeset(machine),
         %Machine{} = machine <- edit_api_key_or_flash(conn, changeset) do
      conn
      |> put_flash(:success, "API key regenerated for machine #{machine.name}.")
      |> redirect(to: Routes.machine_path(conn, :list))
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    user = AuthUtils.get_current_user(conn)

    with %Machine{} = machine <- get_machine_or_404(conn, user, id) do
      # Deactivate machine first, then delete it in a background process, as it may have too much
      # data to delete in request process.
      case do_activate(machine, false) do
        {:ok, _} ->
          Task.start(fn ->
            Repo.delete(machine)

            # Regenerate user's cache to remove references to machine in it
            CacheUtils.update_all!(user)
          end)

          conn
          |> put_flash(
            :success,
            "The machine has been deactivated and will be deleted in a few moments."
          )
          |> redirect(to: Routes.machine_path(conn, :list))

        {:error, _} ->
          conn
          |> put_flash(:error, "Machine could not be deleted.")
          |> redirect(to: Routes.machine_path(conn, :list))
      end
    end
  end

  @spec deactivate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def deactivate(conn, %{"id" => id}) do
    activate_or_deactivate(conn, id, false)
  end

  @spec activate(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def activate(conn, %{"id" => id}) do
    activate_or_deactivate(conn, id, true)
  end

  defp activate_or_deactivate(conn, id, active) do
    user = AuthUtils.get_current_user(conn)
    verb = if active, do: "activated", else: "deactivated"

    with %Machine{} = machine <- get_machine_or_404(conn, user, id) do
      with {:ok, machine} <- do_activate(machine, active) do
        conn
        |> put_flash(:success, "Machine #{machine.name} #{verb}.")
        |> redirect(to: Routes.machine_path(conn, :list))
      else
        {:error, changeset} ->
          conn
          |> put_flash(:error, "Error changing machine activation status.")
          |> render("machines.html", changeset: changeset)
      end
    end
  end

  defp common_assigns(conn) do
    user = AuthUtils.get_current_user(conn)

    conn =
      conn
      |> assign(:user, user)
      |> machines_title()
      |> assign(:machines, ControllerUtils.get_user_machines(user))

    {conn, user}
  end

  # Also checks that user is owner of machine
  defp get_machine_or_404(conn, user, id) do
    from(m in Machine, where: m.id == ^id and m.user_id == ^user.id)
    |> Repo.one()
    |> case do
      %Machine{} = machine ->
        machine

      nil ->
        conn
        |> put_status(404)
        |> render(CodeStatsWeb.ErrorView, "error_404.html")
    end
  end

  defp create_machine(changeset) do
    changeset
    |> Repo.insert()
    |> case do
      {:ok, machine} -> machine
      {:error, changeset} -> changeset
    end
  end

  defp edit_api_key_or_flash(conn, changeset) do
    changeset
    |> Repo.update()
    |> case do
      {:ok, machine} ->
        machine

      {:error, _} ->
        conn
        |> put_flash(:error, "Error regenerating API key.")
        |> redirect(to: Routes.machine_path(conn, :list))
    end
  end

  defp machines_title(conn), do: assign(conn, :title, "Machines")

  defp single_machine_assigns(conn, %Machine{} = machine) do
    conn
    |> assign(:title, "Machine: #{machine.name}")
    |> assign(:machine, machine)
  end

  defp do_activate(%Machine{} = machine, status) when is_boolean(status) do
    machine
    |> Machine.activation_changeset(%{active: status})
    |> Repo.update()
  end
end
