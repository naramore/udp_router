use Mix.Config

config :logger, level: :warn

config :udp_router,
  broadcast_destinations: [],
  port_range: 4040..4060
