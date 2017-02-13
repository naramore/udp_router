defmodule UDPRouter.RouterSupervisor do
  @moduledoc false
  use Supervisor

  @prefix :port

  def start_link(opts \\ []) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      worker(UDPRouter, [], restart: :transient)
    ]
    opts = [strategy: :simple_one_for_one]

    supervise(children, opts)
  end

  def start_router(supervisor, port, opts \\ []) do
    opts = Keyword.put(opts, :name, router_name(port))
    Supervisor.start_child(supervisor, [port, opts])
  end

  def stop_router(supervisor, port) do
    Supervisor.terminate_child(supervisor, router_name(port))
  end

  def start_routers(supervisor, ports, opts \\ []) do
    Enum.map(ports, fn p -> start_router(supervisor, p, opts) end)
  end

  def stop_routers(supervisor, ports) do
    Enum.map(ports, fn p -> stop_router(supervisor, p) end)
  end

  def router_name(port) do
    UDPRouter.Registry.via(:"#{@prefix}_#{port}")
  end
end
