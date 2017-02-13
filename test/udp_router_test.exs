defmodule UDPRouterTest do
  use ExUnit.Case
  alias UDPRouter.FakeTraffic, as: FT

  @ports Application.get_env(:udp_router, :port_range)

  setup do
    {:ok, %{
      wait: 2 * 1000,
      test_time: 10 * 1000,
      ports: @ports,
      ip: {127, 0, 0, 1}}}
  end

  test "fake traffic load", %{wait: wait, test_time: test_time, ports: ports, ip: ip} do
    # start the fake traffic receiver
    {:ok, receiver} = UDPRouter.FakeTraffic.Receiver.start_link()

    # start the fake traffic generator
    {:ok, server} = UDPRouter.FakeTraffic.start_link([dispatch_args: [ip, ports]])
    :ok = UDPRouter.FakeTraffic.activate(server)

    # wait an arbitrary amount of time...
    _ = :timer.sleep(test_time)

    # stop the fake traffic
    :ok = FT.deactivate(server)

    # wait for it to catch up (might not be needed)
    _ = :timer.sleep(wait)

    # check the producer and consumer for what they sent / received
    {:ok, sent} = FT.check(server)
    {:ok, %{count: received, ports: _ports}} = FT.Receiver.check(receiver)
    assert sent == received
  end
end
