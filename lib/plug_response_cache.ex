defmodule PlugResponseCache do
  @type miss :: {:miss, :cold}
              | {:miss, :expired}
              | {:miss, :request_rejected}
              | {:miss, :response_rejected}

  import Plug.Conn

  @defaults [
    enabled: true,
    store: PlugResponseCache.Stores.Ets,
    profile: PlugResponseCache.Profiles.Default
  ]

  def init(options) do
    @defaults
    |> Keyword.merge(Application.get_all_env(:plug_response_cache))
    |> Keyword.merge(options)
    |> Enum.into(%{})
  end

  def call(conn, %{enabled: false}), do: miss(conn, :disabled)

  def call(conn, %{profile: profile} = options) do
    if profile.cache_request?(conn, options) do
      send_cached(conn, options)
    else
      miss(conn, :request_rejected)
    end
  end

  defp send_cached(conn, %{profile: profile, store: store} = options) do
    case store.get(conn) do
      {:hit, {status, body, expires}} ->
        conn
        |> hit(expires)
        |> send_resp(status, body)
        |> halt()

      {:miss, reason} ->
        register_before_send(conn, fn conn ->
          if profile.cache_response?(conn, options) do
            cache_response(conn, reason, options)
          else
            miss(conn, :response_rejected)
          end
        end)
    end
  end

  defp cache_response(conn, miss_reason, %{profile: profile, store: store} = options) do
    expires = profile.expires(conn, options)

    conn
    |> store.set(expires)
    |> miss(miss_reason)
  end

  defp miss(conn, reason) do
    put_private(conn, :response_cache, {:miss, reason})
  end

  defp hit(conn, expires) do
    put_private(conn, :response_cache, {:hit, expires})
  end
end
