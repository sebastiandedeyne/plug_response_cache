defmodule PlugResponseCache.Supervisor do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    [supervisor(PlugResponseCache.Stores.Ets, [])]
    |> Supervisor.start_link(strategy: :one_for_one)
  end
end
