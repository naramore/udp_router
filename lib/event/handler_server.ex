defmodule Event.HandlerServer do
  @moduledoc false
  use GenServer

  def start_link(name, manager_name, handler, opts \\ []) do
    GenServer.start_link(__MODULE__, {name, manager_name, handler}, opts);
  end

  def init({name, manager_name, handler}) do
    state = %{name: name, manager_name: manager_name, handler: handler}
    start_handler(state)
    {:ok, state}
  end

  def start_handler(%{manager_name: manager_name, handler: handler}) do
    :ok = GenEvent.add_mon_handler(manager_name, handler, self())
  end

  def handle_info({:gen_event_EXIT, _handler, reason}, state)
    when reason in [:normal, :shutdown] do
      {:stop, reason, state}
  end

  def handle_info({:gen_event_EXIT, _handler, _reason}, state) do
    start_handler(state)

    {:noreply, state}
  end
end
