defmodule Commanded.Generator.Model.Projection do
  alias Commanded.Generator.Model.{Event, Field}
  alias __MODULE__

  @type t :: %Projection{
          name: String.t(),
          module: atom(),
          events: list(Event.t()),
          fields: list(Field.t())
        }

  defstruct [:name, :module, events: [], fields: []]
end
