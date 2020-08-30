defmodule CodeStatsWeb.Gravatar.Proxy do
  @moduledoc """
  A proxy server for Gravatar pictures.

  This service fetches Gravatar images and caches them into ETS for a time. It also provides
  client API that can be used to check and fetch the images from the cache. If the image doesn't
  exist in the cache, the proxy serializes accesses so that only one fetch from Gravatar is active
  for any given image.
  """

  use GenServer

  require Logger

  import Ex2ms, only: [fun: 1]
  import CodeStats.Utils.TypedStruct

  alias CodeStatsWeb.Gravatar.Utils

  @gravatar_url "https://www.gravatar.com/avatar"
  @cache_table :gravatar_proxy_table
  @cache_clean_interval 300_000
  @cache_lifetime 60 * 60

  @typedoc """
  Response returned to client.

  Either an ok-tuple with image mime type and image data respectively, or `:error`.
  """
  @type response :: {:ok, String.t(), binary()} | :error

  defmodule Options do
    deftypedstruct(%{
      name: GenServer.name()
    })
  end

  defmodule State do
    defmodule FetchData do
      deftypedstruct(%{
        task: Task.t(),
        listeners: {[GenServer.from()], []}
      })
    end

    deftypedstruct(%{
      fetches: {%{optional(Utils.hash()) => FetchData.t()}, %{}},
      refs: {%{optional(reference()) => Utils.hash()}, %{}}
    })
  end

  ### SERVER INTERFACE ###

  @spec start_link(Options.t()) :: GenServer.on_start()
  def start_link(%Options{} = opts) do
    GenServer.start_link(
      __MODULE__,
      %State{},
      name: opts.name
    )
  end

  @impl true
  @spec init(State.t()) :: {:ok, State.t()}
  def init(s) do
    if :ets.info(@cache_table) == :undefined do
      :ets.new(@cache_table, [:named_table, :set, :protected, read_concurrency: true])
    end

    {:ok, s}
  end

  @impl true
  def handle_call(msg, from, state)

  def handle_call({:req, hash}, from, %State{} = state) do
    fetch_data = Map.get(state.fetches, hash)

    fetch_data =
      if not is_nil(fetch_data) do
        %State.FetchData{fetch_data | listeners: [from | fetch_data.listeners]}
      else
        %State.FetchData{
          task: start_fetch(hash),
          listeners: [from]
        }
      end

    fetches = Map.put(state.fetches, hash, fetch_data)
    refs = Map.put(state.refs, fetch_data.task.ref, hash)

    {:noreply, %State{state | fetches: fetches, refs: refs}}
  end

  @impl true
  def handle_info(msg, state)

  def handle_info({ref, data}, %State{} = state) when is_reference(ref) do
    hash = Map.get(state.refs, ref)

    if not is_nil(hash) do
      fetch_data = Map.get(state.fetches, hash)

      case data do
        {:ok, %Mojito.Response{} = resp} ->
          resp_data = process_response(resp)
          Enum.each(fetch_data.listeners, &GenServer.reply(&1, resp_data))
          cache_insert(hash, resp_data)

        :error ->
          Enum.each(fetch_data.listeners, &GenServer.reply(&1, :error))
          cache_insert(hash, :error)
      end

      refs = Map.delete(state.refs, ref)
      fetches = Map.delete(state.fetches, hash)

      {:noreply, %State{state | refs: refs, fetches: fetches}}
    else
      {:noreply, state}
    end
  end

  # Clean cache periodically
  def handle_info(:cache_clean, state) do
    clean_and_reset()
    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  ### CLIENT INTERFACE ###

  @doc """
  Get image from Gravatar proxy with given hash.

  If image data is in cache, it is returned immediately.
  """
  @spec get_image(GenServer.name(), Utils.hash()) :: response()
  def get_image(server, hash) do
    case cache_get(hash) do
      nil -> GenServer.call(server, {:req, hash})
      resp -> resp
    end
  end

  ### PRIVATE INTERFACE ###

  @spec start_fetch(Utils.hash()) :: Task.t()
  defp start_fetch(hash) do
    Task.async(fn ->
      try do
        {:ok, _} =
          hash
          |> form_url()
          |> Mojito.get([], timeout: 2_000)
      rescue
        _ -> :error
      end
    end)
  end

  @spec process_response(Mojito.Response.t()) :: response()
  defp process_response(%Mojito.Response{} = resp) do
    if resp.status_code == 200 do
      {:ok, Mojito.Headers.get(resp.headers, "content-type"), resp.body}
    else
      :error
    end
  end

  @spec gravatar_query() :: String.t()
  defp gravatar_query() do
    size = CodeStats.Utils.get_conf(:gravatar_size)
    default = CodeStats.Utils.get_conf(:gravatar_default)
    rating = CodeStats.Utils.get_conf(:gravatar_rating)

    URI.encode_query(%{
      "size" => size,
      "default" => default,
      "rating" => rating
    })
  end

  @spec form_url(Utils.hash()) :: String.t()
  defp form_url(hash) do
    "#{@gravatar_url}/#{hash}?#{gravatar_query()}"
  end

  @spec cache_get(Utils.hash()) :: response() | nil
  defp cache_get(hash) do
    ms =
      fun do
        {^hash, response, _} -> response
      end

    case :ets.select(@cache_table, ms) do
      [resp] -> resp
      [] -> nil
    end
  end

  @spec cache_insert(Utils.hash(), response()) :: :ok
  defp cache_insert(hash, response) do
    true = :ets.insert(@cache_table, {hash, response, DateTime.utc_now() |> DateTime.to_unix()})
    :ok
  end

  @spec cache_clean_old() :: :ok
  defp cache_clean_old() do
    now = DateTime.utc_now() |> DateTime.to_unix()

    ms =
      fun do
        {_, _, stored_at} when stored_at - ^now > @cache_lifetime -> true
      end

    :ets.select_delete(@cache_table, ms)
    :ok
  end

  @spec clean_and_reset() :: :ok
  defp clean_and_reset() do
    cache_clean_old()
    Process.send_after(self(), :cache_clean, @cache_clean_interval)
    :ok
  end
end
