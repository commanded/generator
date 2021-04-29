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
end
