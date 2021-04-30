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

  def add_event(%Projection{} = projection, %Event{} = event) do
    %Projection{events: events} = projection
    %Event{name: name} = event

    events =
      Enum.reject(events, fn
        %Event{name: ^name} -> true
        %Event{} -> false
      end)

    %Projection{projection | events: Enum.sort_by([event | events], & &1.name)}
  end
end
