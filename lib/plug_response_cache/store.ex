defmodule PlugResponseCache.Store do
  @doc """
  Retrieve a response from the cache. If nothing was found, return a tuple with
  `:miss` and a reason, e.g. `{:miss, :cold}` or `{:miss, :expired}`.
  """
  @callback get(Plug.Conn.t()) :: Plug.Conn.t() | PlugResponseCache.miss()

  @doc """
  Save a response to the cache. The second argument is an expiration time in the
  UTC timezone. If a response should never expire, the expiration time is
  `:never`.
  """
  @callback set(Plug.Conn.t(), DateTime.t() | :never) :: Plug.Conn.t()
end
