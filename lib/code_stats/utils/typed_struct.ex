defmodule CodeStats.Utils.TypedStruct do
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
