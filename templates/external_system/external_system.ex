defmodule <%= @external_system_namespace %>.<%= @external_system_module %> do
  @moduledoc """
  <%= @external_system_name %>.
  """

  <%= @format_aliases.(@events) %>

  <%= for event <- @events do %>
  def handle(%<%= event.module %>{}, _metadata) do
    :ok
  end
  <% end %>
end
