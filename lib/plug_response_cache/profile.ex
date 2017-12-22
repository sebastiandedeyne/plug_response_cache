defmodule PlugResponseCache.Profile do
  @callback cache_request?(Plug.Conn.t(), Map.t()) :: boolean()
  @callback cache_response?(Plug.Conn.t(), Map.t()) :: boolean()
  @callback expires(Plug.Conn.t(), Map.t()) :: DateTime.t() | :never
end
