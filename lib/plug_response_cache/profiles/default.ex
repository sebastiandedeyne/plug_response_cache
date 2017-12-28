defmodule PlugResponseCache.Profiles.Default do
  @behaviour PlugResponseCache.Profile

  alias Plug.Conn

  def cache_request?(%Conn{method: "GET"}, _options), do: true
  def cache_request?(_conn, _options), do: false

  def cache_response?(%Conn{status: status}, _options), do: status < 400
  def cache_response?(_conn, _options), do: true

  def expires(_conn, %{expiration_time: expiration_time}),
    do: :os.system_time(:seconds) + expiration_time * 60

  def expires(_conn, _options), do: :never
end
