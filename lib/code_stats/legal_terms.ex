defmodule CodeStats.LegalTerms do
  @moduledoc """
  Functions to return the contents of legal terms and diffs to the most recent one. The
  contents in this module are created dynamically at compile time.

  "Legal terms" here refers to both privacy policies and terms of service, as they live in the
  same file.

  These terms live in the file `lib/code_stats_web/templates/page/terms.html.eex`.
  """

  # Force recompilation
  @external_resource ".git"

  # Default path of the terms file if not specified
  @default_path "lib/code_stats_web/templates/page/terms.html.eex"

  # List of old legal terms: the git commit hash when the policy was added and the date when
  # it was put into effect. The third element, if not nil, specifies the location of the terms
  # file in that commit. List in descending date order.
  @terms [
    {"dbd2d59f34ab8bd8538029f081f908e2a17b50a2", ~D[2016-08-02],
     "web/templates/page/terms.html.eex"},
    {"a2a5f122546ef2391b441b61199643dd3b2d52e5", ~D[2016-05-30],
     "web/templates/page/terms.html.eex"}
  ]

  # Date when the current legal terms came into effect
  @current_terms_date ~D[2018-07-01]

  for {terms_hash, terms_date, terms_file} <- @terms do
    terms_date = Macro.escape(terms_date)
    terms_file = if not is_nil(terms_file), do: terms_file, else: @default_path
    {contents, 0} = System.cmd("git", ["show", "#{terms_hash}:#{terms_file}"])
    {diff, 0} = System.cmd("git", ["diff", "-w", "#{terms_hash}:#{terms_file}", @default_path])

    def by_date(unquote(terms_date)) do
      {unquote(contents), unquote(diff)}
    end
  end

  @doc """
  Get the legal terms and their diff to the most recent version. If there are no matching legal
  terms, `nil` is returned.
  """
  @spec by_date(Date.t()) :: {String.t(), String.t()} | nil
  def by_date(date) do
    closest_item = Enum.find(@terms, fn {_, d, _} -> Date.compare(date, d) in [:gt, :eq] end)

    if not is_nil(closest_item) do
      by_date(elem(closest_item, 1))
    else
      nil
    end
  end

  @doc """
  Get latest (currently active) version of legal terms.
  """
  @spec get_latest_version() :: Date.t()
  def get_latest_version(), do: @current_terms_date

  @doc """
  Is the given legal terms version the currently active version? If the given date is the same or
  larger than the currently active legal terms date, returns true.
  """
  @spec is_current_version?(Date.t()) :: boolean
  def is_current_version?(version) do
    Date.compare(version, get_latest_version()) in [:gt, :eq]
  end
end
