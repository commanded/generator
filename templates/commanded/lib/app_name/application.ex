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

      # Start the Ecto Repo
      <%= @app_module %>.Repo,

      <%= if Enum.any?(@event_handlers) do %># Start event handlers
      <%= for event_handler <- @event_handlers do %>{<%= event_handler.event_handler_namespace %>.<%= event_handler.event_handler_module %>, hibernate_after: :timer.seconds(15)},
      <% end %><% end %>

      <%= if Enum.any?(@process_managers) do %># Start process managers
      <%= for process_manager <- @process_managers do %>{<%= process_manager.process_manager_namespace %>.<%= process_manager.process_manager_module %>, hibernate_after: :timer.seconds(15)},
      <% end %><% end %>

      <%= if Enum.any?(@projections) do %># Start read model projectors
      <%= for projection <- @projections do %>{<%= projection.projection_namespace %>.<%= projection.projector_module %>, hibernate_after: :timer.seconds(15)},
      <% end %><% end %>
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: <%= @app_module %>.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
