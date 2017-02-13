defmodule Event.Supervisor do
    @moduledoc false
    use Supervisor

    @manager_name Application.get_env(:udp_router, :event_manager)

    def start_link(opts \\ []) do
      Supervisor.start_link(__MODULE__, :ok, Keyword.put(opts, :name, __MODULE__))
    end

    def init(_) do
      children = [
        worker(GenEvent, [[name: @manager_name]]),
        supervisor(Event.HandlersSupervisor, [@manager_name])
      ]

      supervise(children, strategy: :one_for_all)
    end
end
