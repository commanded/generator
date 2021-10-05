defmodule Commanded.Generator.Model.ExternalSystem do
  alias Commanded.Generator.Model.Event
  alias __MODULE__

  @type t :: %ExternalSystem{
          name: String.t(),
          module: atom(),
          events: list(Event.t())
        }

  defstruct [:name, :module, events: []]

  def add_event(%ExternalSystem{} = external_system, %Event{} = event) do
    %ExternalSystem{events: events} = external_system
    %Event{name: name} = event

    events =
      Enum.reject(events, fn
        %Event{name: ^name} -> true
        %Event{} -> false
      end)

    %ExternalSystem{external_system | events: Enum.sort_by([event | events], & &1.name)}
  end
end
