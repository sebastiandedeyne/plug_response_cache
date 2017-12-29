defmodule PlugResponseCache.Profiles.Default do
  @moduledoc """
  The default profile caches all successful GET requests for a specified
  duration in minutes. By default, it will cache the response forever.

  - If a request has a different method that "GET", it will be rejected
  - If a response has a status equal to or higher that 400, it will be rejected
  - The cache will keep the response for the duration of the `expiration_time`
  value (in minutes). If no expiration time is specified, it will be cached
  forever.
  """

  @behaviour PlugResponseCache.Profile

  alias Plug.Conn

  def cache_request?(%Conn{method: "GET"}, _opts), do: true
  def cache_request?(_conn, _opts), do: false

  def cache_response?(%Conn{status: status}, _opts), do: status < 400
  def cache_response?(_conn, _opts), do: true

  def expires(_conn, %{expiration_time: expiration_time}),
    do: :os.system_time(:seconds) + expiration_time * 60

  def expires(_conn, _opts), do: :never
end
