defmodule ResponseCache.Cache do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get(conn) do
    GenServer.call(__MODULE__, {:get, conn.request_path})
  end

  def set(conn) do
    GenServer.cast(__MODULE__, {:set, conn.request_path, {conn.status, conn.resp_body}})
    conn
  end

  def clear, do: clear(sync: false)
  def clear(sync: false), do: GenServer.cast(__MODULE__, {:clear})
  def clear(sync: true), do: GenServer.call(__MODULE__, {:clear})

  def init(:ok) do
    :ets.new(:response_cache, [:set, :protected, :named_table])
    {:ok, nil}
  end

  def handle_call({:get, path}, _from, nil) do
    case :ets.lookup(:response_cache, path) do
      [{_, response} | _] -> {:reply, response, nil}
      [] -> {:reply, :miss, nil}
    end
  end

  def handle_call({:clear}, nil) do
    :ets.delete_all_objects(:response_cache)
    {:ok, nil}
  end

  def handle_cast({:set, path, {status, body}}, nil) do
    :ets.insert(:response_cache, {path, {status, body}})
    {:noreply, nil}
  end

  def handle_cast({:clear}, nil) do
    :ets.delete_all_objects(:response_cache)
    {:noreply, nil}
  end
end
