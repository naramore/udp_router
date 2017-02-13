defmodule Event do
  @moduledoc false

  def notify({_level, _header, _msg, _details} = msg, %{event_manager: em}) do
    GenEvent.notify(em, msg)
  end
  def notify(_msg, _state), do: :ok
end
