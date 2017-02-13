defmodule UDPRouter.Supervisor do
  @moduledoc false
  use Supervisor

  @destinations Application.get_env(:udp_router, :broadcast_destinations)
  @pool_size Application.get_env(:udp_router, :pool_size)
  @pool_overflow Application.get_env(:udp_router, :pool_overflow)
  @pool_name Application.get_env(:udp_router, :pool_name)
  @handler Application.get_env(:udp_router, :handler)

  def start_link(opts \\ []) do
    {args, opts} = defaults(opts)
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init({size, overflow}) do
    import Supervisor.Spec, warn: false

    config = poolboy_config(size, overflow)
    children = [
      worker(UDPRouter.Registry, []),
      supervisor(Event.Supervisor, []),
      supervisor(UDPRouter.RouterSupervisor, []),
      :poolboy.child_spec(:worker, config, @destinations)
    ]
    opts = [strategy: :one_for_one]

    supervise(children, opts)
  end

  defp poolboy_config(size, overflow) do
    [{:name, {:local, @pool_name}},
     {:worker_module, @handler},
     {:size, size},
     {:max_overflow, overflow}]
  end

  defp defaults(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    {size, opts} = Keyword.pop(opts, :pool_size, @pool_size)
    {overflow, opts} = Keyword.pop(opts, :pool_overflow, @pool_overflow)

    {{size, overflow}, opts}
  end
end
