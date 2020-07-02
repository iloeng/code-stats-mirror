defmodule CodeStatsWeb.Gravatar.Utils do
  @typedoc """
  Gravatar hash (MD5 of a string).
  """
  @type hash :: String.t()

  @doc """
  Convert given email to Gravatar hash. In effect, this returns an md5 hash of the given string.

  ## Examples

      iex> CodeStatsWeb.Gravatar.email_to_hash("foo")
      "acbd18db4cc2f85cedef654fccc4a4d8"

      iex> CodeStatsWeb.Gravatar.email_to_hash("foo@bar.example")
      "356321a16f5bfa0ac6fe84b259cfa3e3"
  """
  @spec email_to_hash(String.t()) :: hash()
  def email_to_hash(email) when is_binary(email) do
    hexlify(:crypto.hash(:md5, email))
  end

  @spec hexlify(binary()) :: hash()
  defp hexlify(digest) do
    hexlify_byte(digest, "")
  end

  @spec hexlify_byte(binary(), String.t()) :: binary()
  defp hexlify_byte(digest, processed)

  defp hexlify_byte(<<h::4, l::4, rest::bits>>, processed),
    do: hexlify_byte(rest, processed <> <<hexlify_nibble(h), hexlify_nibble(l)>>)

  defp hexlify_byte("", processed), do: processed

  @spec hexlify_nibble(integer()) :: integer()
  defp hexlify_nibble(val) when val < 10, do: ?0 + val
  defp hexlify_nibble(val), do: ?a + val - 10
end
