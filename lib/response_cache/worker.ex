defmodule ResponseCache.Worker do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def terminate(reason, _state) do
    throw(reason)
  end

  def init(:ok) do
    :ets.new(:response_cache, [:set, :protected, :named_table])
    {:ok, nil}
  end

  def handle_call({:get, path}, _from, nil) do
    case :ets.lookup(:response_cache, path) do
      [{_, response} | _] -> {:reply, response, nil}
      [] -> {:reply, nil, nil}
    end
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
