defmodule UDPRouter do
  @moduledoc false
  use GenServer

  @udp_options Application.get_env(:udp_router, :udp_options)
  @default_event_manager Application.get_env(:udp_router, :event_manager)
  @pool_name Application.get_env(:udp_router, :pool_name)

  def start_link(port, opts \\ []) do
    {manager, opts} = Keyword.pop(opts, :event_manager, @default_event_manager)
    {udp_opts, opts} = Keyword.pop(opts, :udp_opts, @udp_options)
    GenServer.start_link(__MODULE__, {port, manager, udp_opts}, opts)
  end

  def stop(server) do
    GenServer.call(server, :stop)
  end

  def init({port, em, opts}) do
    case :gen_udp.open(port, opts) do
      {:ok, socket} ->
        state = %{port: port, opts: opts, socket: socket, event_manager: em}
        _ = Event.notify({:debug, :listening, port, [socket: socket, transport: :gen_udp]}, state)
        {:ok, state}
      {:error, reason} -> {:stop, reason}
      otherwise -> {:stop, {:unknown, otherwise}}
    end
  end

  def handle_call(:stop, _from, %{port: port, socket: socket} = state) do
    response = :gen_udp.close(socket)
    _ = Event.notify({:debug, :closed, port, [socket: socket, transport: :gen_udp]}, state)
    {:stop, :normal, {:ok, response}, state}
  end

  def handle_call(request, from, state) do
    _ = Event.notify({:warn, :unhandled_call, request, [from: from]}, state)
    {:reply, :ok, state}
  end

  def handle_cast(request, state) do
    _ = Event.notify({:warn, :unhandled_cast, request, []}, state)
    {:noreply, state}
  end

  def handle_info({:udp, socket, ip, port, data}, %{port: p} = state) do
    _ = Event.notify({:debug, :handling, data, [socket: socket, ip: ip, port: port]}, state)
    _ = :poolboy.transaction(@pool_name, fn(pid) ->
      GenServer.cast(pid, {p, data})
    end)
    _ = Event.notify({:debug, :handled, nil, [socket: socket, ip: ip, port: port]}, state)
    {:noreply, state}
  end

  def handle_info(request, state) do
    _ = Event.notify({:warn, :unhandled_info, request, []}, state)
    {:noreply, state}
  end
end
