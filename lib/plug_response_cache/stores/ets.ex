defmodule PlugResponseCache.Stores.Ets do
  @moduledoc """
  The ETS store, which is used by default, is a `GenServer` that stores the
  response bodies in an [ETS](http://erlang.org/doc/man/ets.html) table.
  """

  @behaviour PlugResponseCache.Store

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get(conn) do
    case :ets.lookup(:response_cache, conn.request_path) do
      [{_, response} | _] -> response_if_alive(response)
      [] -> {:miss, :cold}
    end
  end

  def set(conn, expires) do
    GenServer.cast(__MODULE__, {:set, conn.request_path, {conn.status, conn.resp_body, expires}})
    conn
  end

  def clear, do: :ets.delete_all_objects(:response_cache)

  def init(:ok) do
    :ets.new(:response_cache, [:set, :protected, :named_table])
    {:ok, nil}
  end

  defp response_if_alive({_, _, :never} = response), do: {:hit, response}

  defp response_if_alive({_, _, expiration_time} = response) do
    if DateTime.diff(expiration_time, DateTime.utc_now()) > 0 do
      {:hit, response}
    else
      {:miss, :expired}
    end
  end

  def handle_cast({:set, path, {status, body, expires}}, nil) do
    :ets.insert(:response_cache, {path, {status, body, expires}})
    {:noreply, nil}
  end
end
