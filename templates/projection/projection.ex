defmodule <%= @projection_namespace %>.<%= @projection_module %> do
  @moduledoc """
  <%= @projection_name %>.
  """

  use Ecto.Schema

  schema "<%= @projection_table %>" do
    # Fields ...
  end
end
