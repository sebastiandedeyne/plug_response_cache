defmodule ResponseCache.Profiles.Default do
  @behaviour ResponseCache.Profile

  alias Plug.Conn

  def cache_request?(%Conn{method: "GET"}), do: true
  def cache_request?(_conn), do: false

  def cache_response?(%Conn{status: status}), do: status < 400
  def cache_response?(_conn), do: true

  def expires(_conn), do: :never
end
