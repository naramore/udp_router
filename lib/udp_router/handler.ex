defmodule UDPRouter.Handler.FakeProcess do
  @moduledoc false

  def process(pkt) do
    {:ok, pkt}
  end
end

defmodule UDPRouter.Handler.Process do
  @moduledoc false

  def process(_pkt) do
    # TODO: put your actual processing logic here
  end
end

defmodule UDPRouter.Handler do
  @moduledoc false
  use GenServer

  @event_manager Application.get_env(:udp_router, :event_manager)
  @processor Application.get_env(:udp_router, :processor)

  def start_link(destinations, opts \\ []) do
    {manager, opts} = Keyword.pop(opts, :event_manager, @event_manager)
    {processor, opts} = Keyword.pop(opts, :processor, @processor)
    GenServer.start_link(__MODULE__, {manager, processor, destinations}, opts)
  end

  def init({manager, processor, destinations}) do
    {:ok, %{event_manager: manager, processor: processor, destinations: destinations}}
  end

  def handle_cast({port, <<_::size(64),_::binary>> = msg}, state) do
    _ = Event.notify({:debug, :handling_msg, msg, [port: port]}, state)
    _ = case update_headers(msg, state) do
      {:ok, updated_msg} ->
        broadcast(updated_msg, Map.get(state, :destinations, []), port)
      {:error, reason} ->
        _ = Event.notify({:warn, :handling_error, reason, [port: port]}, state)
        :error
    end
    _ = Event.notify({:debug, :handled_msg, msg, [port: port]}, state)
    {:noreply, state}
  end
  def handle_cast({port, <<_::binary>> = msg}, state) do
    _ = Event.notify({:warn, :unsupported_binary_format, msg, [port: port]}, state)
    {:noreply, state}
  end
  def handle_cast(request, state) do
    _ = Event.notify({:warn, :unsupported_msg_format, request, []}, state)
    {:noreply, state}
  end

  def handle_call(request, from, state) do
    _ = Event.notify({:warn, :unhandled_call, request, [from: from]}, state)
    {:reply, :ok, state}
  end

  def handle_info(request, state) do
    _ = Event.notify({:warn, :unhandled_info, request, []}, state)
    {:noreply, state}
  end

  defp update_headers(msg, %{processor: {m, f}} = state) do
    with {:ok, parsed_msg} <- Protocol.UDP.decode(msg),
         {:ok, updated_msg} <- apply(m, f, [parsed_msg]),
          _ <- Event.notify({:debug, :parsed, parsed_msg, []}, state),
         {:ok, re_encoded_msg} <- Protocol.UDP.encode(updated_msg) do
           {:ok, re_encoded_msg}
         else
           {:error, reason} -> {:error, reason}
           otherwise -> {:error, {:unknown, otherwise}}
         end
  end

  defp broadcast(msg, destinations, port) do
    {:ok, socket} = :gen_udp.open(0)
    _ = Enum.map(destinations, fn
      {ip, p} ->
        :gen_udp.send(socket, ip, p, msg)
      pid when is_pid(pid) ->
        send(pid, {:udp, nil, nil, port, msg})
      name ->
        case UDPRouter.Registry.lookup(name) do
          [{pid, _}] ->
            send(pid, {:udp, nil, nil, port, msg})
          _ ->
            :ok
        end
    end)
    :gen_udp.close(socket)
  end
end
