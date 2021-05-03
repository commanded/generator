defmodule <%= @command_namespace %>.<%= @command_module %> do
  @moduledoc """
  <%= @command_name %> command.
  """

  alias __MODULE__

  @type t :: %<%= @command_module %>{
    <%= @aggregate %>_id: String.t()
  }

  defstruct [
    :<%= @aggregate %>_id
  ]
end
