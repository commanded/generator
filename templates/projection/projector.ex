defmodule <%= @projection_namespace %>.<%= @projector_module %> do
  @moduledoc """
  <%= @projection_name %> Projector.
  """

  use Commanded.Projections.Ecto,
    application: <%= @commanded_application_module %>,
    repo: <%= @app_module %>.Repo,
    name: __MODULE__,
    start_from: :origin

  <%= @format_aliases.(@events) %>

  <%= for event <- @events do %>
  project %<%= event.module %>{}, _metadata, fn multi ->
    multi
  end
  <% end %>

  @impl Commanded.Event.Handler
  def error(_error, _failed_event, _failure_context) do
    :skip
  end
end
