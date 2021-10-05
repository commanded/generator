defmodule Commanded.Generator.Model do
  alias Commanded.Generator.Model.{
    Aggregate,
    Command,
    Event,
    EventHandler,
    ExternalSystem,
    ProcessManager,
    Projection
  }

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
    external_systems: [],
    process_managers: [],
    projections: []
  ]

  def new(namespace) do
    %Model{namespace: namespace}
  end

  def add_event_handler(%Model{} = model, %EventHandler{} = event_handler) do
    %Model{event_handlers: event_handlers} = model
    %EventHandler{name: name} = event_handler

    event_handlers =
      Enum.reject(event_handlers, fn
        %EventHandler{name: ^name} -> true
        %EventHandler{} -> false
      end)

    %Model{model | event_handlers: Enum.sort_by([event_handler | event_handlers], & &1.name)}
  end

  def add_external_system(%Model{} = model, %ExternalSystem{} = external_system) do
    %Model{external_systems: external_systems} = model
    %ExternalSystem{name: name} = external_system

    external_systems =
      Enum.reject(external_systems, fn
        %ExternalSystem{name: ^name} -> true
        %ExternalSystem{} -> false
      end)

    %Model{
      model
      | external_systems: Enum.sort_by([external_system | external_systems], & &1.name)
    }
  end

  def add_process_manager(%Model{} = model, %ProcessManager{} = process_manager) do
    %Model{process_managers: process_managers} = model
    %ProcessManager{name: name} = process_manager

    process_managers =
      Enum.reject(process_managers, fn
        %ProcessManager{name: ^name} -> true
        %ProcessManager{} -> false
      end)

    %Model{
      model
      | process_managers: Enum.sort_by([process_manager | process_managers], & &1.name)
    }
  end

  def add_projection(%Model{} = model, %Projection{} = projection) do
    %Model{projections: projections} = model
    %Projection{name: name} = projection

    projections =
      Enum.reject(projections, fn
        %Projection{name: ^name} -> true
        %Projection{} -> false
      end)

    %Model{
      model
      | projections: Enum.sort_by([projection | projections], & &1.name)
    }
  end

  def find_aggregate(%Model{} = model, name) do
    %Model{aggregates: aggregates} = model

    Enum.find(aggregates, fn
      %Aggregate{name: ^name} -> true
      %Aggregate{} -> false
    end)
  end

  def find_command(%Model{} = model, module, name) do
    %Model{aggregates: aggregates, commands: commands} = model

    aggregates
    |> Stream.flat_map(fn %Aggregate{commands: commands} -> commands end)
    |> Stream.concat(commands)
    |> Enum.find(fn
      %Command{module: ^module, name: ^name} -> true
      %Command{} -> false
    end)
  end

  def find_event(%Model{} = model, module, name) do
    %Model{aggregates: aggregates, events: events} = model

    aggregates
    |> Stream.flat_map(fn %Aggregate{events: events} -> events end)
    |> Stream.concat(events)
    |> Enum.find(fn
      %Event{module: ^module, name: ^name} -> true
      %Event{} -> false
    end)
  end

  def find_event_handler(%Model{} = model, name) do
    %Model{event_handlers: event_handlers} = model

    Enum.find(event_handlers, fn
      %EventHandler{name: ^name} -> true
      %EventHandler{} -> false
    end)
  end

  def find_external_system(%Model{} = model, name) do
    %Model{external_systems: external_systems} = model

    Enum.find(external_systems, fn
      %ExternalSystem{name: ^name} -> true
      %ExternalSystem{} -> false
    end)
  end

  def find_process_manager(%Model{} = model, name) do
    %Model{process_managers: process_managers} = model

    Enum.find(process_managers, fn
      %ProcessManager{name: ^name} -> true
      %ProcessManager{} -> false
    end)
  end

  def find_projection(%Model{} = model, name) do
    %Model{projections: projections} = model

    Enum.find(projections, fn
      %Projection{name: ^name} -> true
      %Projection{} -> false
    end)
  end
end
