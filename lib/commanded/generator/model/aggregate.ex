defmodule Commanded.Generator.Model.Aggregate do
  alias Commanded.Generator.Model.{Command, Event}
  alias __MODULE__

  @type t :: %Aggregate{
          name: String.t(),
          module: atom(),
          commands: list(Command.t()),
          events: list(Event.t())
        }

  defstruct [:name, :module, commands: [], events: []]
end
