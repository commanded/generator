defmodule Commanded.Generator.Source.MiroTest do
  use ExUnit.Case

  import Tesla.Mock

  alias Commanded.Generator.Model
  alias Commanded.Generator.Model.{Aggregate, Command, Event, Projection}
  alias Commanded.Generator.Source.Miro

  describe "source from Miro" do
    test "with a single event" do
      mock_request("boards/widgets/list_all_single_event.json")

      {:ok, model} = Miro.build(namespace: MyApp, board_id: "o9J_lJibPCc=")

      assert match?(
               %Model{
                 events: [
                   %Event{name: "Something Happened", module: MyApp.SomethingHappened}
                 ]
               },
               model
             )
    end

    test "with a single aggregate, command, and event" do
      mock_request("boards/widgets/list_all_single_aggregate_command_event.json")

      {:ok, model} = Miro.build(namespace: MyApp, board_id: "o9J_lJibPCc=")

      assert match?(
               %Model{
                 aggregates: [
                   %Aggregate{
                     name: "An Aggregate",
                     module: MyApp.AnAggregate,
                     commands: [
                       %Command{name: "Do Something", module: MyApp.DoSomething}
                     ],
                     events: [
                       %Event{name: "Something Happened", module: MyApp.SomethingHappened}
                     ]
                   }
                 ]
               },
               model
             )
    end

    test "with one of all supported types" do
      mock_request("boards/widgets/list_all.json")

      {:ok, model} = Miro.build(namespace: MyApp, board_id: "o9J_lJibPCc=")

      assert match?(
               %Model{
                 aggregates: [
                   %Aggregate{
                     name: "Aggregate",
                     module: MyApp.Aggregate,
                     commands: [
                       %Command{name: "Command", module: MyApp.Command}
                     ],
                     events: [
                       %Event{name: "Event", module: MyApp.Event}
                     ]
                   }
                 ],
                 event_handlers: [],
                 process_managers: [],
                 projections: [
                   %Projection{
                     name: "Read Model",
                     module: MyApp.ReadModel
                   }
                 ]
               },
               model
             )
    end
  end

  defp mock_request(path) do
    mock(fn
      %{method: :get, url: "https://api.miro.com/v1/boards/o9J_lJibPCc=/widgets/"} ->
        %Tesla.Env{
          status: 200,
          headers: [{"content-type", "application/json"}],
          body: File.read!("test/fixtures/miro/" <> path)
        }
    end)
  end
end
