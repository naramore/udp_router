# UDPRouter

Listens for UDP packets on the specified sockets, processes them, and then broadcasts the new packets to the specified destinations.

## Installation

1. Install Erlang & Elixir (see [here](http://elixir-lang.org/install.html))
2. Clone this repository
3. Update the configuration to suit your needs
4. Add a real processing function to the current UDPRouter.Handler or just create you own handler and update the configuration.
5. Build (from project directory)

  ```bash
  mix deps.get
  mix compile
  ```

6. Test (from project directory)

  ```bash
  mix test --trace
  ```

7. Interactive Development (from project directory)

  ```bash
  iex -S mix
  ```

## Learn more

  * Elixir Official website: http://elixir-lang.org
  * Elixir Crash Course: http://elixir-lang.org/crash-course.html
  * Erlang Downloads: https://www.erlang-solutions.com/resources/download.html
  * Erlang Installation from GitHub: https://github.com/erlang/otp/blob/maint/HOWTO/INSTALL.md
  * Erlang wxWidgets GTK Installation: https://github.com/wxWidgets/wxWidgets/blob/master/docs/gtk/install.txt
  * Erlang Installation from Basho: http://docs.basho.com/riak/1.3.0/tutorials/installation/Installing-Erlang
