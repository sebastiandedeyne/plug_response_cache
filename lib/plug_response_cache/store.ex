defmodule PlugResponseCache.Store do
  @doc """
  Retrieve a response from the cache. If nothing was found, return a tuple with
  `:miss` and a reason, e.g. `{:miss, :cold}` or `{:miss, :expired}`.
  """
  @callback get(Plug.Conn.t()) :: PlugResponseCache.hit() | PlugResponseCache.miss()

  @doc """
  Save a response to the cache. The second argument is an expiration time in the
  UTC timezone. If a response should never expire, the expiration time is
  `:never`.
  """
  @callback set(Plug.Conn.t(), PlugResponseCache.expire_time()) :: Plug.Conn.t()
end
