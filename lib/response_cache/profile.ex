defmodule ResponseCache.Profile do
  @callback cache_request?(Plug.Conn.t()) :: boolean()
  @callback cache_response?(Plug.Conn.t()) :: boolean()
  @callback expires(Plug.Conn.t()) :: DateTime.t | :never
end
