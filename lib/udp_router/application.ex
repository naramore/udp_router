defmodule UDPRouter.Application do
  @moduledoc false
  use Application

  @ports Application.get_env(:udp_router, :port_range)

  def start(_type, _args) do
    app = UDPRouter.Supervisor.start_link()
    _ = initialize_listeners_on(@ports)

    app
  end

  def initialize_listeners_on(ports, opts \\ []) do
    router_sup = UDPRouter.RouterSupervisor
    router_sup.start_routers(router_sup, ports, opts)
  end
end
