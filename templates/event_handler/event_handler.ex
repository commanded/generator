defmodule <%= @event_handler_namespace %>.<%= @event_handler_module %> do
  @moduledoc """
  <%= @event_handler_name %> event handler.
  """

  use Commanded.Event.Handler,
    application: <%= @commanded_application_module %>,
    name: __MODULE__,
    start_from: :origin

  <%= @format_aliases.(@events) %>
  alias __MODULE__

  <%= for event <- @events do %>
  @impl Commanded.Event.Handler
  def handle(%<%= event.module %>{} = event, _metadata) do
    %<%= event.module %>{} = event

    # TODO: Handle <%= event.name %>

    :ok
  end
  <% end %>

  @impl Commanded.Event.Handler
  def error(_error, _failed_event, _failure_context) do
    :skip
  end
end
