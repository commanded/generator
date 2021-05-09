defmodule <%= @app_module %>.Router do
  @moduledoc false

  use Commanded.Commands.Router

  <%= for aggregate <- @aggregates do %>
  alias <%= aggregate.aggregate_namespace %>.<%= aggregate.aggregate_module %>
  <%= @format_aliases.(aggregate.commands) %>
  <% end %>

  <%= for aggregate <- @aggregates do %>
  identify(<%= aggregate.aggregate_module %>, by: <%= aggregate.aggregate_id %>, prefix: "<%= aggregate.aggregate_prefix %>-")
  <% end %>

  <%= for aggregate <- @aggregates do %>
  <%= if Enum.any?(aggregate.commands) do %>
  dispatch([<%= Enum.map(aggregate.commands, &(&1.module)) |> Enum.join(", ") %>], to: <%= aggregate.aggregate_module %>)
  <% end %>
  <% end %>
end
