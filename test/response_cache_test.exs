defmodule ResponseCacheTest do
  use ExUnit.Case
  import Plug.Conn
  import Supervisor.Spec
  alias Plug.Conn
  alias ResponseCache
  alias ResponseCache.Profiles.AllGetRequests

  test "the default profile caches a succesful GET request" do
    first_conn =
      build_conn("GET", "/")
      |> resp(200, "Foo")
      |> ResponseCache.call(profile: AllGetRequests, enabled: true)

    # The connection should't be sent since it's the cache's first request.
    assert first_conn.state == :set

    first_conn = send_resp(first_conn)

    # After sending, we expect the response to be written to the cache.
    assert first_conn.private[:response_cache] == {:miss, :cold}

    second_conn =
      build_conn("GET", "/")
      |> resp(200, "Bar")
      |> ResponseCache.call(profile: AllGetRequests, enabled: true)

    # Since we're expecting to have something in the cache, the response should
    # already be sent, because the response cache should halt the plug pipeline.
    assert second_conn.state == :sent
    assert second_conn.private[:response_cache] == {:hit, :never}
    assert second_conn.resp_body == "Foo"
  end

  test "the response cache does nothing when disabled" do
    first_conn =
      build_conn("GET", "/")
      |> resp(200, "Foo")
      |> ResponseCache.call(enabled: false)
      |> send_resp()

    assert first_conn.private[:response_cache] == {:miss, :disabled}

    second_conn =
      build_conn("GET", "/")
      |> resp(200, "Bar")
      |> ResponseCache.call(enabled: false)

    assert second_conn.private[:response_cache] == {:miss, :disabled}
    assert second_conn.resp_body == "Bar"
  end

  test "the default profile only caches GET requests" do
    conn =
      build_conn("POST", "/")
      |> resp(200, "")
      |> ResponseCache.call(profile: AllGetRequests, enabled: true)
      |> send_resp()

    assert conn.private[:response_cache] == {:miss, :rejected}
  end

  defp build_conn(method, path, params_or_body \\ nil) do
    Plug.Adapters.Test.Conn.conn(%Conn{}, method, path, params_or_body)
  end
end
