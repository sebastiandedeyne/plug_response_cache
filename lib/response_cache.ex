defmodule ResponseCache do
  import Plug.Conn
  alias ResponseCache.Worker

  def init(options), do: options

  def call(conn, opts) when is_list(opts),
    do: call(conn, Enum.into(opts, %{}))

  def call(conn, %{enabled: false}),
    do: put_private(conn, :response_cache, {:miss, :disabled})

  def call(conn, %{profile: profile}) do
    case apply(profile, :cache?, [conn]) do
      true -> send_cached(conn)
      false -> put_private(conn, :response_cache, {:miss, :rejected})
    end
  end

  def clear do
    GenServer.cast(Worker, {:clear})
  end

  defp send_cached(conn) do
    case get_cached(conn) do
      nil ->
        register_before_send(conn, fn conn ->
          conn
          |> cache_response()
          |> put_private(:response_cache, {:miss, :cold})
        end)

      {status, body} ->
        conn
        |> put_private(:response_cache, {:hit, :never})
        |> send_resp(status, body)
        |> halt()
    end
  end

  defp get_cached(conn) do
    GenServer.call(Worker, {:get, conn.request_path})
  end

  defp cache_response(conn) do
    GenServer.cast(Worker, {:set, conn.request_path, {conn.status, conn.resp_body}})
    conn
  end
end
