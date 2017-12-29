defmodule PlugResponseCache do
  @moduledoc """
  The response cache plug can cache an entire response body for a set amount of
  time.

  To enable the cache, add the plug to your pipeline as early as possible.
  Here's what that looks like in a clean Phoenix installation:

      pipeline :browser do
        plug(:accepts, ["html"])
        plug(PlugResponseCache)
        plug(:fetch_session)
        plug(:fetch_flash)
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end

  The plug should be configured with the `:plug_response_cache` config key. This
  belongs in your application's configuration file:

      config :plug_response_cache,
        enabled: false,
        store: MyApp.ResponseCache.MyCustomStore
        profile: MyApp.ResponseCache.MyCustomProfile

  - `enabled`: Enables or disables the response cache entirely (default: `true`)
  - `store`: A custom cache store — a module that implements
  `PlugResponseCache.Store` callbacks (default: `PlugResponseCache.Stores.Ets`)
  - `profile`: A custom cache profile — a module that implements
  `PlugResponseCache.Profile` callbacks (default:
  `PlugResponseCache.Profiles.Default`)
  - `debug`: Logs the response cache's result on every request when `true`
  (default: `false`)

  Since every option has a default, the response cache will also work without
  specifying any custom configuration.

  Options are also passed to the cache profile, so if a profile has options
  simply add them to the list. For example, the default profile
  (`PlugResponseCache.Profiles.Default`) has an `expiration_time` option to
  determine for how many minutes the response should be cached.

      config :plug_response_cache,
        expiration_time: 5

  It's also possible to pass options to the plug. This is useful for enabling or
  disabling the response cache on the fly, or for toggling the debug mode.

      pipeline :browser do
        # ...
        plug(PlugResponseCache, debug: true)
        # ...
      end

  It's not recommended to configure the profile & store like this because they
  might require a supervisor, which needs to be known ahead of time.
  """

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
    debug: false,
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

  def call(conn, %{enabled: false} = opts), do: mark_miss(conn, :disabled, opts.debug)

  def call(conn, opts) do
    if opts.profile.cache_request?(conn, opts) do
      send_cached(conn, opts)
    else
      mark_miss(conn, :request_rejected, opts.debug)
    end
  end

  defp send_cached(conn, opts) do
    case opts.store.get(conn) do
      {:hit, {status, body, expires}} ->
        conn
        |> mark_hit(expires, opts.debug)
        |> send_resp(status, body)
        |> halt()

      {:miss, reason} ->
        register_before_send(conn, fn conn ->
          if opts.profile.cache_response?(conn, opts) do
            cache_response(conn, reason, opts)
          else
            mark_miss(conn, :response_rejected, opts.debug)
          end
        end)
    end
  end

  defp cache_response(conn, miss_reason, opts) do
    expires = opts.profile.expires(conn, opts)

    conn
    |> opts.store.set(expires)
    |> mark_miss(miss_reason, opts.debug)
  end

  defp mark_miss(conn, reason, debug) do
    if debug, do: debug(:miss, reason)
    put_private(conn, :plug_response_cache, {:miss, reason})
  end

  defp mark_hit(conn, expires, debug) do
    if debug, do: debug(:hit, expires)
    put_private(conn, :plug_response_cache, {:hit, expires})
  end

  defp debug(:miss, reason),
    do: IO.puts("PlugResponseCache MISS - " <> Atom.to_string(reason))

  defp debug(:hit, :never),
    do: IO.puts("PlugResponseCache HIT - cached forever")

  defp debug(:hit, expire_time),
    do: IO.puts("PlugResponseCache HIT - expires " <> DateTime.to_iso8601(expire_time))
end
