defmodule ResponseCache.Profile do
  @callback cache?(Plug.Conn.t()) :: boolean()
  @callback expires(Plug.Conn.t()) :: DateTime.t | :never
end
