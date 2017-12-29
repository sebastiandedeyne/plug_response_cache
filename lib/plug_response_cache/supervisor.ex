defmodule PlugResponseCache.Supervisor do
  @moduledoc """
  The supervisor takes care of all processes that the response cache requires.

  The only process that needs to be run is the ETS store. It will only be
  started if the response cache is configured to use it.
  """

  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    store = Application.get_env(:plug_response_cache, :store, PlugResponseCache.Stores.Ets)

    if store == PlugResponseCache.Stores.Ets do
      Supervisor.start_link([supervisor(store, [])], strategy: :one_for_one)
    end
  end
end
