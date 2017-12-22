defmodule PlugResponseCache do
  import Plug.Conn
  alias PlugResponseCache.Cache

  def init(options) do
    Enum.into(options, %{
      enabled: true,
      profile: PlugResponseCache.Profiles.Default
    })
  end

  def call(conn, %{enabled: false}), do: miss(conn, :disabled)

  def call(conn, %{profile: profile} = options) do
    case profile.cache_request?(conn) do
      true -> send_cached(conn, options)
      false -> miss(conn, :request_rejected)
    end
  end

  def clear, do: Cache.clear()
  def clear(options), do: Cache.clear(options)

  defp send_cached(conn, %{profile: profile}) do
    case Cache.get(conn) do
      :miss ->
        register_before_send(conn, fn conn ->
          case profile.cache_response?(conn) do
            true -> cache_response(conn)
            false -> miss(conn, :response_rejected)
          end
        end)

      {status, body} ->
        conn
        |> hit(:never)
        |> send_resp(status, body)
        |> halt()
    end
  end

  defp cache_response(conn) do
    conn
    |> Cache.set()
    |> miss(:cold)
  end

  defp miss(conn, reason) do
    put_private(conn, :response_cache, {:miss, reason})
  end

  defp hit(conn, expires) do
    put_private(conn, :response_cache, {:hit, expires})
  end
end
