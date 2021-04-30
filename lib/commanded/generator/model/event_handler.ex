defmodule Commanded.Generator.Model.EventHandler do
  alias Commanded.Generator.Model.Event
  alias __MODULE__

  @type t :: %EventHandler{
          name: String.t(),
          module: atom(),
          events: list(Event.t())
        }

  defstruct [:name, :module, events: []]
end
