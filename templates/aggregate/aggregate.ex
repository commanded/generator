defmodule <%= @aggregate_namespace %>.<%= @aggregate_module %> do
  @moduledoc """
  <%= @aggregate_name %> aggregate.
  """

  <%= @format_aliases.(@commands) %>
  <%= @format_aliases.(@events) %>
  alias __MODULE__

  defstruct [
    :<%= @aggregate %>_id
  ]

  <%= for command <- @commands do %>
  def execute(%<%= @aggregate_module %>{} = <%= @aggregate %>, %<%= command.module %>{} = command) do
    :ok
  end
  <% end %>

  # State mutators

  <%= for event <- @events do %>
  def apply(%<%= @aggregate_module %>{} = <%= @aggregate %>, %<%= event.module %>{} = event) do
    <%= @aggregate %>
  end
  <% end %>
end
