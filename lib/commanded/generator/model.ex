defmodule Commanded.Generator.Model do
  alias Commanded.Generator.Model.{Aggregate, Event}
  alias __MODULE__

  @type t :: %Model{
          namespace: atom(),
          aggregates: list(Aggregate.t()),
          events: list(Event.t())
        }

  defstruct [
    :namespace,
    aggregates: [],
    commands: [],
    events: [],
    event_handlers: [],
    process_managers: [],
    projections: []
  ]

  def new(namespace) do
    %Model{namespace: namespace}
  end

  def find_event(%Model{} = model, id) do
    %Model{aggregates: aggregates, events: events} = model

    aggregates
    |> Stream.flat_map(fn %Aggregate{events: events} -> events end)
    |> Stream.concat(events)
    |> Enum.find(fn
      %Event{id: ^id} -> true
      %Event{} -> false
    end)
  end
end
