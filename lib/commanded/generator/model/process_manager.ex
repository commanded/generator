defmodule Commanded.Generator.Model.ProcessManager do
  alias Commanded.Generator.Model.Event
  alias __MODULE__

  @type t :: %ProcessManager{
          name: String.t(),
          module: atom(),
          events: list(Event.t())
        }

  defstruct [:name, :module, events: []]

  def add_event(%ProcessManager{} = process_manager, %Event{} = event) do
    %ProcessManager{events: events} = process_manager
    %Event{name: name} = event

    events =
      Enum.reject(events, fn
        %Event{name: ^name} -> true
        %Event{} -> false
      end)

    %ProcessManager{process_manager | events: Enum.sort_by([event | events], & &1.name)}
  end
end
