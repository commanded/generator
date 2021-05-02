defmodule <%= @aggregate_namespace %>.<%= @aggregate_module %> do
  @moduledoc """
  <%= @aggregate_name %> aggregate.
  """

  <%= for command <- @commands do %>
  alias <%= command.namespace %>.<%= command.module %><% end %>
  <%= for event <- @events do %>
  alias <%= event.namespace %>.<%= event.module %><% end %>

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
