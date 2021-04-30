defmodule Commanded.Generator.Model.ProcessManager do
  alias Commanded.Generator.Model.Event
  alias __MODULE__

  @type t :: %ProcessManager{
          name: String.t(),
          module: atom(),
          events: list(Event.t())
        }

  defstruct [:name, :module, events: []]
end
