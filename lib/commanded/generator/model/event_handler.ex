defmodule Commanded.Generator.Model.EventHandler do
  alias Commanded.Generator.Model.Event
  alias __MODULE__

  @type t :: %EventHandler{
          name: String.t(),
          module: atom(),
          events: list(Event.t())
        }

  defstruct [:name, :module, events: []]

  def add_event(%EventHandler{} = event_handler, %Event{} = event) do
    %EventHandler{events: events} = event_handler
    %Event{name: name} = event

    events =
      Enum.reject(events, fn
        %Event{name: ^name} -> true
        %Event{} -> false
      end)

    %EventHandler{event_handler | events: Enum.sort_by([event | events], & &1.name)}
  end
end
