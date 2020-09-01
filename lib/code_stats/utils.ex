defmodule CodeStats.Utils do
  @moduledoc """
  Contains non-Phoenix-specific utilities that don't fit anywhere else.
  """

  @doc """
  Get configuration setting.

  Uses Application.get_env to get the given setting's value.
  """
  @spec get_conf(atom) :: any
  def get_conf(key) do
    Application.get_env(:code_stats, key)
  end

  defmodule TypedStruct do
    @moduledoc """
    A typed struct implementation to make them less painful.
    """

    @type typespec :: any()
    @type enforced :: {typespec(), :enforced}
    @type has_default :: {typespec(), any()}
    @type field_spec :: typespec() | enforced() | has_default()
    @type field_map :: %{optional(atom()) => field_spec()}

    @doc """
    Create typed struct with a type, default values, and enforced keys.

    Input should be a map where the key names are names of the struct keys and values are the
    field information. The value can be a typespec, in which case the field will be enforced, or
    a 2-tuple of `{typespec, default_value}`, making the field unenforced.

    To prevent ambiguity, a value of `{typespec, :ts_enforced}` will be interpreted as enforced,
    this will allow you to typespec a 2-tuple.

    NOTE: Due to the ambiguity removal technique above, `:ts_enforced` is not allowed as a default
    value.

    Example:

    ```elixir
    deftypedstruct(%{
      # Enforced with simple type
      foo: integer(),

      # Enforced 2-tuple typed field, written like this to remove ambiguity
      bar: {{String.t(), integer()}, :ts_enforced},

      # Non-enforced field with default value
      baz: {any(), ""}
    })
    ```
    """
    @spec deftypedstruct(field_map()) :: term()
    defmacro deftypedstruct(fields) do
      fields_list =
        case fields do
          {:%{}, _, flist} -> flist
          _ -> raise ArgumentError, "Fields must be a map!"
        end

      enforced_list =
        fields_list
        |> Enum.filter(fn
          {_, {_, :ts_enforced}} -> true
          {_, {_, _}} -> false
          {_, _} -> true
        end)
        |> Enum.map(&elem(&1, 0))

      field_specs =
        Enum.map(fields_list, fn
          {field, {typespec, :ts_enforced}} ->
            {field, typespec}

          {field, {typespec, _}} ->
            {field, typespec}

          {field, typespec} ->
            {field, typespec}
        end)

      field_vals =
        Enum.map(fields_list, fn
          {field, {_, :ts_enforced}} -> field
          {field, {_, default}} -> {field, default}
          {field, _} -> field
        end)

      quote do
        @type t :: %__MODULE__{unquote_splicing(field_specs)}
        @enforce_keys unquote(enforced_list)
        defstruct unquote(field_vals)
      end
    end
  end
end
