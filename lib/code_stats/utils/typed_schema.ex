defmodule CodeStats.Utils.TypedSchema do
  @doc """
  Define an Ecto schema with an associated `@type t` specification.

  Works the same as normal Ecto schemas, but third argument of each field is the typespec to use
  for that field. Typespec for `timestamps` is automatically generated and cannot be specified.
  Supported Ecto macros are `field`, `belongs_to`, `has_many`, `has_one`. `many_to_many` is not
  supported.

  Note: For `has_many`, remember to specify the typespec as a list.

  Does not work for embedded schemas.
  """
  defmacro deftypedschema(table, do: fields) do
    fields =
      case fields do
        {:__block__, _meta, flist} -> flist
        field -> [field]
      end

    fielddatas = for field <- fields, do: parse_spec(field)

    typespecs =
      Enum.reduce(fielddatas, [], fn
        %{field: :timestamps}, acc ->
          [
            {:updated_at, quote(do: DateTime.t())},
            {:inserted_at, quote(do: DateTime.t())}
            | acc
          ]

        %{field: field, typespec: typespec, func: func}, acc ->
          acc = [{field, typespec} | acc]

          if func == :belongs_to do
            # If given spec includes nil, add nil to ID spec too
            spec =
              case typespec do
                {:|, _, [x, y]} when is_nil(x) or is_nil(y) -> quote(do: pos_integer() | nil)
                _ -> quote(do: pos_integer())
              end

            [{String.to_atom("#{field}_id"), spec} | acc]
          else
            acc
          end
      end)
      |> Enum.reverse()

    fieldspecs = Enum.map(fielddatas, & &1.fieldspec)

    quote do
      use Ecto.Schema

      @type t :: %__MODULE__{
              unquote_splicing(typespecs),
              __meta__: Ecto.Schema.Metadata.t(),
              id: pos_integer()
            }

      schema unquote(table) do
        (unquote_splicing(fieldspecs))
      end
    end
  end

  defp parse_spec(ast)

  defp parse_spec({:timestamps, _meta, _args} = ast) do
    %{
      field: :timestamps,
      func: :timestamps,
      fieldspec: ast,
      typespec: nil
    }
  end

  defp parse_spec({func, meta, [field, type, typespec | rest]}) do
    %{
      field: field,
      func: func,
      fieldspec: {func, meta, [field, type | rest]},
      typespec: typespec
    }
  end
end
