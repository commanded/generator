defmodule <%= @event_namespace %>.<%= @event_module %> do
  @moduledoc """
  <%= @event_name %> event.
  """

  alias __MODULE__

  @type t :: %<%= @event_module %>{    
  }

  @derive Jason.Encoder
  defstruct []
end
