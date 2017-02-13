defmodule UDPRouter.Registry do
  @moduledoc false

  @registry_name Application.get_env(:udp_router, :registry)

  def start_link(name \\ @registry_name) do
    resp = Registry.start_link(:unique, name)
    _ = Application.get_all_env(:udp_router)
      |> Keyword.delete(:included_applications)
      |> Enum.map(fn {k, v} ->
        UDPRouter.Registry.register(k, v)
      end)

    resp
  end

  def via(name, registry \\ @registry_name) do
    {:via, Registry, {registry, name}}
  end

  def register(key, value \\ [], registry \\ @registry_name) do
    Registry.register(registry, key, value)
  end

  def unregister(key, registry \\ @registry_name) do
    Registry.unregister(registry, key)
  end

  def lookup(key, registry \\ @registry_name) do
    Registry.lookup(registry, key)
  end

  def lookup_value(key, default \\ nil, registry \\ @registry_name) do
    case Registry.lookup(registry, key) do
      [{_pid, value}] -> value
      _ -> default
    end
  end
end
