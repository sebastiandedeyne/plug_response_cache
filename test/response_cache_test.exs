defmodule PlugResponseCacheTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  alias Plug.Conn
  alias PlugResponseCache

  test "the default profile caches a succesful GET request" do
    options = PlugResponseCache.init([])

    first_conn =
      build_conn("GET", "/the-default-profile-caches-a-succesful-get-request")
      |> resp(200, "Foo")
      |> PlugResponseCache.call(options)

    # The connection should't be sent since it's the cache's first request.
    assert first_conn.state == :set

    first_conn = send_resp(first_conn)

    # After sending, we expect the response to be written to the cache.
    assert first_conn.private[:plug_response_cache] == {:miss, :cold}

    :timer.sleep(100)

    second_conn =
      build_conn("GET", "/the-default-profile-caches-a-succesful-get-request")
      |> resp(200, "Bar")
      |> PlugResponseCache.call(options)

    # Since we're expecting to have something in the cache, the response should
    # already be sent, because the response cache should halt the plug pipeline.
    assert second_conn.state == :sent
    assert second_conn.private[:plug_response_cache] == {:hit, :never}
    assert second_conn.resp_body == "Foo"
  end

  test "the response cache does nothing when disabled" do
    options = PlugResponseCache.init(enabled: false)

    first_conn =
      build_conn("GET", "/the-response-cache-does-nothing-when-disabled")
      |> resp(200, "Foo")
      |> PlugResponseCache.call(options)
      |> send_resp()

    assert first_conn.private[:plug_response_cache] == {:miss, :disabled}

    :timer.sleep(100)

    second_conn =
      build_conn("GET", "/the-response-cache-does-nothing-when-disabled")
      |> resp(200, "Bar")
      |> PlugResponseCache.call(options)

    assert second_conn.private[:plug_response_cache] == {:miss, :disabled}
    assert second_conn.resp_body == "Bar"
  end

  test "the default profile only caches GET requests" do
    options = PlugResponseCache.init([])

    conn =
      build_conn("POST", "/the-default-profile-only-caches-get-requests")
      |> resp(200, "")
      |> PlugResponseCache.call(options)
      |> send_resp()

    assert conn.private[:plug_response_cache] == {:miss, :request_rejected}
  end

  test "the default profile only caches successful requests" do
    options = PlugResponseCache.init([])

    conn =
      build_conn("GET", "/the-default-profile-only-caches-successful-requests")
      |> resp(500, "")
      |> PlugResponseCache.call(options)
      |> send_resp()

    assert conn.private[:plug_response_cache] == {:miss, :response_rejected}
  end

  test "the default profile accepts an expiration time in minutes" do
    options = PlugResponseCache.init(expiration_time: 5)

    first_conn =
      build_conn("GET", "/the-default-profile-accepts-an-expiration-time-in-minutes")
      |> resp(200, "Foo")
      |> PlugResponseCache.call(options)
      |> send_resp()

    assert first_conn.private[:plug_response_cache] == {:miss, :cold}

    :timer.sleep(100)

    second_conn =
      build_conn("GET", "/the-default-profile-accepts-an-expiration-time-in-minutes")
      |> resp(200, "Bar")
      |> PlugResponseCache.call(options)

    {:hit, expires} = second_conn.private[:plug_response_cache]

    expires_from_now = DateTime.diff(expires, DateTime.utc_now())

    assert round(expires_from_now / 60) == 5
  end

  test "the response cache returns a miss if the hit is expired" do
    options = PlugResponseCache.init(expiration_time: 0)

    first_conn =
      build_conn("GET", "/the-response-cache-returns-a-miss-if-the-hit-is-expired")
      |> resp(200, "Foo")
      |> PlugResponseCache.call(options)
      |> send_resp()

    assert first_conn.private[:plug_response_cache] == {:miss, :cold}

    :timer.sleep(100)

    second_conn =
      build_conn("GET", "/the-response-cache-returns-a-miss-if-the-hit-is-expired")
      |> resp(200, "Bar")
      |> PlugResponseCache.call(options)
      |> send_resp()

    assert second_conn.private[:plug_response_cache] == {:miss, :expired}
    assert second_conn.resp_body == "Bar"
  end

  defp build_conn(method, path, params_or_body \\ nil) do
    Plug.Adapters.Test.Conn.conn(%Conn{}, method, path, params_or_body)
  end
end
