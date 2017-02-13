# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger,
  backends: [:console],
  format: "$time $metadata[$level] $levelpad$message\n",
  metadata: [:request_id],
  compile_time_purge_level: :debug,
  level: :info,
  utc_log: true,
  truncate: 8192,
  sync_threshold: 20,
  handle_otp_reports: true,
  discard_threshold_for_error_logger: 500

config :udp_router,
  broadcast_destinations: [],                               # @type broadcast_destinations :: [{{int, int, int, int}, int} | pid | term]
                                                            #   a list of destinations following one of these forms:
                                                            #     1. {ip_address, port}, where port is an integer, and ip is a 4-tuple of integers for IPv4
                                                            #     2. pid, where pid is the process id that you would like to send a message to
                                                            #     3. name, that is transformed into a pid by looking it up in the UDPRouter.Registry
  port_range: 4040..4060,                                   # any enumeration of integer values
  pool_size: 1000,                                          # number of workers that ALL UDPRouters have available
  pool_overflow: 100,                                       # number of workers above the pool size
  pool_name: :worker,                                       # name of the worker / handler pool
  handler: UDPRouter.Handler,                               # name of the worker / handler
  processor: {UDPRouter.Handler.FakeProcess, :process},     # {module, :function_atom} for processing function of 1 argument
  udp_options: [:binary, active: true, reuseaddr: true],    # options passed to :gen_udp.open(port, options)
  event_manager: Event.Manager,                             # name of the event manager (where notifications are sent)
  event_handler_server: Event.HandlerServer,                # name of the event handler server
  event_handler: Event.ConsoleHandler,                      # name of the event handler (e.g. ConsoleHandler logs to console, NullHandler does nothing)
  registry: UDPRouter.Registry                              # name of the registry

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :udp_router, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:udp_router, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).

import_config "#{Mix.env}.exs"
