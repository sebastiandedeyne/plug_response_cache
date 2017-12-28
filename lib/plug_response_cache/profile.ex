defmodule PlugResponseCache.Profile do
  @doc """
  Determines whether or not the request should be cached or retrieved from the
  cache. This callback gets executed *before* the request is handled by your
  application.

  The default profile checks the request type here, since it only caches "GET"
  requests.
  """
  @callback cache_request?(Plug.Conn.t(), Map.t()) :: boolean()

  @doc """
  Determines whether or not the request should be cached. This callback gets
  executed *after* the request is handled by your application.

  The default profile checks the response code here, since it only caches
  successful responses.
  """
  @callback cache_response?(Plug.Conn.t(), Map.t()) :: boolean()

  @doc """
  Returns the expiration time of the cached response in the UTC timezone.
  Returns a `:never` atom. If the response shouldn't expire automatically.
  """
  @callback expires(Plug.Conn.t(), Map.t()) :: DateTime.t() | :never
end
