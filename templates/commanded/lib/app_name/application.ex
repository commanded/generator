defmodule <%= @app_module %>.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Start the Commanded application
      <%= @app_module %>.App,

      # Start a worker by calling: <%= @app_module %>.Worker.start_link(arg)
      # {<%= @app_module %>.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: <%= @app_module %>.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
