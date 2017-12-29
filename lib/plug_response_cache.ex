defmodule PlugResponseCache do
  @type expire_time :: DateTime.t() | :never
  @type hit :: {:hit, {Plug.Conn.status(), Plug.Conn.body(), expire_time()}}
  @type miss ::
          {:miss, :cold}
          | {:miss, :expired}
          | {:miss, :request_rejected}
          | {:miss, :response_rejected}

  import Plug.Conn

  @defaults [
    enabled: true,
    store: PlugResponseCache.Stores.Ets,
    profile: PlugResponseCache.Profiles.Default
  ]

  @doc """
  While you can pass options to the plug, it's recommended to configure the
  response cache through the application's config, so the response cache has the
  necessary processes running.
  """
  def init(opts) do
    @defaults
    |> Keyword.merge(Application.get_all_env(:plug_response_cache))
    |> Keyword.merge(opts)
    |> Enum.into(%{})
  end

  def call(conn, %{enabled: false}), do: miss(conn, :disabled)

  def call(conn, opts) do
    if opts.profile.cache_request?(conn, opts) do
      send_cached(conn, opts)
    else
      miss(conn, :request_rejected)
    end
  end

  defp send_cached(conn, opts) do
    case opts.store.get(conn) do
      {:hit, {status, body, expires}} ->
        conn
        |> hit(expires)
        |> send_resp(status, body)
        |> halt()

      {:miss, reason} ->
        register_before_send(conn, fn conn ->
          if opts.profile.cache_response?(conn, opts) do
            cache_response(conn, reason, opts)
          else
            miss(conn, :response_rejected)
          end
        end)
    end
  end

  defp cache_response(conn, miss_reason, opts) do
    expires = opts.profile.expires(conn, opts)

    conn
    |> opts.store.set(expires)
    |> miss(miss_reason)
  end

  defp miss(conn, reason) do
    put_private(conn, :plug_response_cache, {:miss, reason})
  end

  defp hit(conn, expires) do
    put_private(conn, :plug_response_cache, {:hit, expires})
  end
end
