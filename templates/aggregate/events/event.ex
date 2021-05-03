defmodule <%= @event_namespace %>.<%= @event_module %> do
  @moduledoc """
  <%= @event_name %> event.
  """

  alias __MODULE__

  @type t :: %<%= @event_module %>{
    <%= @aggregate %>_id: String.t()
  }

  @derive Jason.Encoder
  defstruct [
    :<%= @aggregate %>_id
  ]
end
