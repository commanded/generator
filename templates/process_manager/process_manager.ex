defmodule <%= @process_manager_namespace %>.<%= @process_manager_module %> do
  @moduledoc """
  <%= @process_manager_name %>.
  """

  use Commanded.ProcessManagers.ProcessManager,
    application: <%= @commanded_application_module %>,
    name: __MODULE__,
    start_from: :origin

  <%= @format_aliases.(@events) %>
  alias __MODULE__

  @derive Jason.Encoder
  defstruct [
    :process_uuid
  ]

  <%= for event <- @events do %>
  @impl Commanded.ProcessManagers.ProcessManager
  def interested?(%<%= event.module %>{}) do
    # TODO: {:start, process_uuid} | {:continue, process_uuid} | {:stop, process_uuid}
  end
  <% end %>

  <%= for event <- @events do %>
  @impl Commanded.ProcessManagers.ProcessManager
  def handle(%<%= @process_manager_module %>{}, %<%= event.module %>{}) do
    []
  end
  <% end %>

  <%= for event <- @events do %>
  @impl Commanded.ProcessManagers.ProcessManager
  def apply(%<%= @process_manager_module %>{} = state, %<%= event.module %>{}) do
    state
  end
  <% end %>

  @impl Commanded.ProcessManagers.ProcessManager
  def error(_error, _failure_source, _failure_context) do
    :skip
  end
end
