defmodule ResponseCacheTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  alias Plug.Conn
  alias ResponseCache

  test "the default profile caches a succesful GET request" do
    options = ResponseCache.init([])

    first_conn =
      build_conn("GET", "/the-default-profile-caches-a-succesful-get-request")
      |> resp(200, "Foo")
      |> ResponseCache.call(options)

    # The connection should't be sent since it's the cache's first request.
    assert first_conn.state == :set

    first_conn = send_resp(first_conn)

    # After sending, we expect the response to be written to the cache.
    assert first_conn.private[:response_cache] == {:miss, :cold}

    second_conn =
      build_conn("GET", "/the-default-profile-caches-a-succesful-get-request")
      |> resp(200, "Bar")
      |> ResponseCache.call(options)

    # Since we're expecting to have something in the cache, the response should
    # already be sent, because the response cache should halt the plug pipeline.
    assert second_conn.state == :sent
    assert second_conn.private[:response_cache] == {:hit, :never}
    assert second_conn.resp_body == "Foo"
  end

  test "the response cache does nothing when disabled" do
    options = ResponseCache.init(enabled: false)

    first_conn =
      build_conn("GET", "/the-response-cache-does-nothing-when-disabled")
      |> resp(200, "Foo")
      |> ResponseCache.call(options)
      |> send_resp()

    assert first_conn.private[:response_cache] == {:miss, :disabled}

    second_conn =
      build_conn("GET", "/the-response-cache-does-nothing-when-disabled")
      |> resp(200, "Bar")
      |> ResponseCache.call(options)

    assert second_conn.private[:response_cache] == {:miss, :disabled}
    assert second_conn.resp_body == "Bar"
  end

  test "the default profile only caches GET requests" do
    options = ResponseCache.init([])

    conn =
      build_conn("POST", "/the-default-profile-only-caches-get-requests")
      |> resp(200, "")
      |> ResponseCache.call(options)
      |> send_resp()

    assert conn.private[:response_cache] == {:miss, :request_rejected}
  end

  test "the default profile only caches successful requests" do
    options = ResponseCache.init([])

    conn =
      build_conn("GET", "/the-default-profile-only-caches-successful-requests")
      |> resp(500, "")
      |> ResponseCache.call(options)
      |> send_resp()

    assert conn.private[:response_cache] == {:miss, :response_rejected}
  end

  defp build_conn(method, path, params_or_body \\ nil) do
    Plug.Adapters.Test.Conn.conn(%Conn{}, method, path, params_or_body)
  end
end
