defmodule Event.HandlersSupervisor do
  @moduledoc false

  use Supervisor

  @handler_server Application.get_env(:udp_router, :event_handler_server)
  @handler Application.get_env(:udp_router, :event_handler)

  def start_link(mgr_name, opts \\ []) do
    Supervisor.start_link(__MODULE__, mgr_name, opts)
  end

  def init(manager_name) do
    children = [
      worker(Event.HandlerServer, [@handler_server, manager_name, @handler])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
