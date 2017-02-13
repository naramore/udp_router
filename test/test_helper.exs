ExUnit.start()

defmodule UDPRouterTest.Utils do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: false

      defmacro safe_env_change(changes \\ %{}) do
        quote do
          storage = for {app, values} <- unquote(changes) do
            for {k, v} <- values do
              stored = Application.get_env(app, k)
              Application.put_env(app, k, v)
              {app, k, stored}
            end
          end |> List.flatten

          on_exit fn ->
            for {app, key, stored} <- storage do
              Application.put_env(app, key, stored)
            end
            :ok
          end
        end
      end
    end
  end
end

defmodule UDPRouter.FakeTraffic do
  @moduledoc false
  use GenServer

  def start_link(opts \\ []) do
    {fun, opts} = Keyword.pop(opts, :dispatch_fun, {UDPRouter.FakeTraffic, :default_dispatcher})
    {args, opts} = Keyword.pop(opts, :dispatch_args, [{124, 0, 0, 1}, 8080..9080])
    opts = Keyword.put(opts, :name, UDPRouter.Registry.via(__MODULE__))
    GenServer.start_link(__MODULE__, {fun, args}, opts)
  end

  def activate(server) do
    GenServer.call(server, :activate)
  end

  def deactivate(server) do
    GenServer.call(server, :deactivate)
  end

  def check(server) do
    GenServer.call(server, :check)
  end

  def init({fun, args}) do
    {:ok, %{count: 0, status: :inactive, dispatch_fun: fun, dispatch_args: args}}
  end

  def handle_call(:check, _from, %{count: count} = state) do
    {:reply, {:ok, count}, state}
  end
  def handle_call(:activate, _from, state) do
    _ = GenServer.cast(self(), :dispatch)
    {:reply, :ok, %{state | status: :active}}
  end
  def handle_call(:deactivate, _from, state) do
    {:reply, :ok, %{state | status: :inactive}}
  end
  def handle_call(_request, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(:dispatch, %{status: :inactive} = state) do
    {:noreply, state}
  end
  def handle_cast(:dispatch, %{status: :active, count: count} = state) do
    {:ok, msg} = generate_packet()
    _ = dispatch(msg, state)
    _ = GenServer.cast(self(), :dispatch)
    {:noreply, %{state | count: count + 1}}
  end
  def handle_cast(_request, state) do
    {:noreply, state}
  end

  def handle_info(_request, state) do
    {:noreply, state}
  end

  def default_dispatcher(address, port_range, msg) do
    port = Enum.random(port_range)
    {:ok, socket} = :gen_udp.open(0)
    :ok = :gen_udp.send(socket, address, port, msg)
    :gen_udp.close(socket)
  end

  def generate_packet() do
    n = Enum.random(1..100)
    %Protocol.UDP{
      header: %Protocol.UDP.Header{
        srcport: Enum.random(1..9000),
        destport: Enum.random(1..9000),
        length: n + 8,
        checksum: <<0, 0>>
        },
      data: random_string(n)
    } |> Protocol.UDP.encode()
  end

  defp random_string(n) when n > 0 do
    alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numeric = "0123456789"
    chars = alpha <> String.downcase(alpha) <> numeric
      |> String.split("", trim: true)
    Enum.map(1..n, fn _ -> Enum.random(chars) end)
      |> Enum.join()
  end
  defp random_string(_), do: ""

  defp dispatch(msg, %{dispatch_fun: f, dispatch_args: args}) do
    execute(f, args ++ [msg])
  end
  defp dispatch(_msg, _state), do: :error

  defp execute({m, f}, args), do: apply(m, f, args)
  defp execute(f, args), do: apply(f, args)
end

defmodule UDPRouter.FakeTraffic.Receiver do
  @moduledoc false
  use GenServer

  def start_link(opts \\ []) do
    opts = Keyword.merge([name: UDPRouter.Registry.via(__MODULE__)], opts)
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def check(server) do
    GenServer.call(server, :get_state)
  end

  def init(:ok) do
    {:ok, %{count: 0, ports: %{}}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end
  def handle_call(_request, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_request, state) do
    {:noreply, state}
  end

  def handle_info({:udp, _, _, port, _msg}, %{count: c, ports: ps} = state) do
    {:noreply, %{state | count: c + 1, ports: Map.update(ps, port, 1, &(&1 + 1))}}
  end
  def handle_info(_request, state) do
    {:noreply, state}
  end
end
