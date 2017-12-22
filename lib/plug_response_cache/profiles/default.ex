defmodule PlugResponseCache.Profiles.Default do
  @behaviour PlugResponseCache.Profile

  alias Plug.Conn

  def cache_request?(%Conn{method: "GET"}, _options), do: true
  def cache_request?(_conn, _options), do: false

  def cache_response?(%Conn{status: status}, _options), do: status < 400
  def cache_response?(_conn, _options), do: true

  def expires(_conn, %{expiration_time: expiration_time}), do: minutes_from_now(expiration_time)
  def expires(_conn, _options), do: :never

  defp minutes_from_now(minutes) do
    unix = DateTime.to_unix(DateTime.utc_now()) + minutes * 60

    DateTime.from_unix!(unix)
  end
end
