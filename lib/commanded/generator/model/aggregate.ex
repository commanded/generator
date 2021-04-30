defmodule Commanded.Generator.Model.Aggregate do
  alias Commanded.Generator.Model.{Command, Event, Field}
  alias __MODULE__

  @type t :: %Aggregate{
          name: String.t(),
          module: atom(),
          fields: list(Field.t()),
          commands: list(Command.t()),
          events: list(Event.t())
        }

  defstruct [:name, :module, fields: [], commands: [], events: []]

  def add_command(%Aggregate{} = aggregate, %Command{} = command) do
    %Aggregate{commands: commands} = aggregate
    %Command{name: name} = command

    commands =
      Enum.reject(commands, fn
        %Command{name: ^name} -> true
        %Command{} -> false
      end)

    %Aggregate{aggregate | commands: Enum.sort_by([command | commands], & &1.name)}
  end

  def add_event(%Aggregate{} = aggregate, %Event{} = event) do
    %Aggregate{events: events} = aggregate
    %Event{name: name} = event

    events =
      Enum.reject(events, fn
        %Event{name: ^name} -> true
        %Event{} -> false
      end)

    %Aggregate{aggregate | events: Enum.sort_by([event | events], & &1.name)}
  end
end
