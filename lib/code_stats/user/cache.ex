defmodule CodeStats.User.Cache do
  @moduledoc """
  User cache is data stored in the user's cache JSON field.
  """

  @doc """
  Struct for storing user cache data when processing it. Data is read from DB in `db_t` form and
  must be passed through `CacheUtils.unformat_cache_from_db/1` to get it in struct form.
  """
  defstruct languages: %{},
            machines: %{},
            dates: %{},
            hours: %{},
            caching_duration: 0.0,
            total_caching_duration: 0.0

  @type languages_t :: %{optional(integer) => integer}
  @type machines_t :: %{optional(integer) => integer}
  @type dates_t :: %{optional(Date.t()) => integer}
  @type hours_t :: %{optional(integer) => integer}

  @type t :: %__MODULE__{
          # Map of language total XPs, key is language ID
          languages: languages_t,
          # Map of machine total XPs, key is machine ID
          machines: machines_t,
          # Map of date total XPs, key is date (Date)
          dates: dates_t,
          # Map of hour total XPs, key is hour (integer)
          hours: hours_t,
          # How long in seconds it took to update cache partially
          caching_duration: float,
          # How long in seconds it took to update cache totally
          total_caching_duration: float
        }

  # Cache data as read from DB, with string keys
  @type db_t :: %{
          optional(String.t()) => integer | float
        }
end
