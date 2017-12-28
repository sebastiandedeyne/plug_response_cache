defmodule PlugResponseCache do
  import Plug.Conn
  alias PlugResponseCache.Cache

  def init(options) do
    Application.get_all_env(:response_cache)
    |> Keyword.merge(options)
    |> Enum.into(%{})
  end

  def call(conn, %{enabled: false}), do: miss(conn, :disabled)

  def call(conn, %{profile: profile} = options) do
    case profile.cache_request?(conn, options) do
      true -> send_cached(conn, options)
      false -> miss(conn, :request_rejected)
    end
  end

  def clear, do: Cache.clear()
  def clear(options), do: Cache.clear(options)

  defp send_cached(conn, %{profile: profile} = options) do
    case Cache.get(conn) do
      {:miss, reason} ->
        register_before_send(conn, fn conn ->
          case profile.cache_response?(conn, options) do
            true -> cache_response(conn, reason, options)
            false -> miss(conn, :response_rejected)
          end
        end)

      {status, body, expires} ->
        conn
        |> hit(expires)
        |> send_resp(status, body)
        |> halt()
    end
  end

  defp cache_response(conn, miss_reason, %{profile: profile} = options) do
    expires = profile.expires(conn, options)

    conn
    |> Cache.set(expires)
    |> miss(miss_reason)
  end

  defp miss(conn, reason) do
    put_private(conn, :response_cache, {:miss, reason})
  end

  defp hit(conn, expires) do
    put_private(conn, :response_cache, {:hit, expires})
  end
end
