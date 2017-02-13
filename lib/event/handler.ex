defmodule Event.ConsoleHandler do
  @moduledoc false
  use GenEvent
  require Logger

  def init(state) do
    {:ok, state}
  end

  def handle_event({level, header, msg, details}, state) do
    prefix = Enum.reduce(details, "[console] [#{header}] ", fn {k, v}, acc ->
      "#{acc}[#{k}: #{inspect(v)}] "
    end)
    _ = Logger.log(level, "#{prefix}#{inspect(msg)}")
    {:ok, state}
  end

  def handle_info(msg, state) do
    _ = Logger.warn("[unhandled_message] #{inspect msg}")
    {:ok, state}
  end
end

defmodule Event.NullHandler do
  @moduledoc false
  use GenEvent

  def init(state) do
    {:ok, state}
  end

  def handle_event(_msg, state) do
    {:ok, state}
  end

  def handle_info(_msg, state) do
    {:ok, state}
  end
end
