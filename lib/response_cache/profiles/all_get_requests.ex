defmodule ResponseCache.Profiles.AllGetRequests do
  @behaviour ResponseCache.Profile

  alias Plug.Conn

  def cache?(%Conn{method: "GET"}), do: true
  def cache?(_conn), do: false

  def expires(_conn), do: :never
end
