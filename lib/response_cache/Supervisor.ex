defmodule ResponseCache.Supervisor do
  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    [supervisor(ResponseCache.Worker, [])]
    |> Supervisor.start_link([strategy: :one_for_one])
  end
end
