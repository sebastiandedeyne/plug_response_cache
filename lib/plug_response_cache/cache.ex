defmodule PlugResponseCache.Cache do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get(conn) do
    GenServer.call(__MODULE__, {:get, conn.request_path})
  end

  def set(conn, expires) do
    GenServer.cast(__MODULE__, {:set, conn.request_path, {conn.status, conn.resp_body, expires}})
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
      [{_, response} | _] ->
        {_, _, expiration_time} = response

        cond do
          expiration_time == :never ->
            {:reply, response, nil}

          DateTime.diff(expiration_time, DateTime.utc_now()) > 0 ->
            {:reply, response, nil}

          true ->
            {:reply, {:miss, :expired}, nil}
        end

      [] ->
        {:reply, {:miss, :cold}, nil}
    end
  end

  def handle_call({:clear}, nil) do
    :ets.delete_all_objects(:response_cache)
    {:ok, nil}
  end

  def handle_cast({:set, path, {status, body, expires}}, nil) do
    :ets.insert(:response_cache, {path, {status, body, expires}})
    {:noreply, nil}
  end

  def handle_cast({:clear}, nil) do
    :ets.delete_all_objects(:response_cache)
    {:noreply, nil}
  end
end
