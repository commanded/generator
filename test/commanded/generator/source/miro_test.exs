defmodule Commanded.Generator.Source.MiroTest do
  use ExUnit.Case

  import Tesla.Mock

  alias Commanded.Generator.Model

  alias Commanded.Generator.Model.{
    Aggregate,
    Command,
    Event,
    EventHandler,
    Field,
    ProcessManager,
    Projection
  }

  alias Commanded.Generator.Source.Miro

  describe "source from Miro" do
    test "with a single event" do
      mock_request("boards/widgets/list_all_single_event.json")

      {:ok, model} = Miro.build(namespace: MyApp, board_id: "o9J_lJibPCc=")

      assert match?(
               %Model{
                 events: [
                   %Event{name: "Something Happened", module: MyApp.Events.SomethingHappened}
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
                       %Command{
                         name: "Do Something",
                         module: MyApp.AnAggregate.Commands.DoSomething
                       }
                     ],
                     events: [
                       %Event{
                         name: "Something Happened",
                         module: MyApp.AnAggregate.Events.SomethingHappened
                       }
                     ]
                   }
                 ],
                 events: []
               },
               model
             )
    end

    test "with one of all supported types" do
      mock_request("boards/widgets/list_all.json")

      {:ok, model} = Miro.build(namespace: MyApp, board_id: "o9J_lJibPCc=")

      assert match?(
               %Model{
                 namespace: MyApp,
                 aggregates: [
                   %Aggregate{
                     name: "Aggregate",
                     module: MyApp.Aggregate,
                     commands: [
                       %Command{
                         name: "Command",
                         module: MyApp.Aggregate.Commands.Command
                       }
                     ],
                     events: [
                       %Event{
                         name: "Event",
                         module: MyApp.Aggregate.Events.Event
                       }
                     ]
                   }
                 ],
                 event_handlers: [
                   %EventHandler{
                     name: "Event Handler",
                     module: MyApp.Handlers.EventHandler,
                     events: [
                       %Event{
                         name: "Event",
                         module: MyApp.Aggregate.Events.Event
                       }
                     ]
                   }
                 ],
                 process_managers: [
                   %ProcessManager{
                     name: "Process Manager",
                     module: MyApp.Processes.ProcessManager,
                     events: [
                       %Event{
                         name: "Event",
                         module: MyApp.Aggregate.Events.Event
                       }
                     ]
                   }
                 ],
                 projections: [
                   %Projection{
                     name: "Projection",
                     module: MyApp.Projections.Projection,
                     events: [
                       %Event{
                         name: "Event",
                         module: MyApp.Aggregate.Events.Event
                       }
                     ]
                   }
                 ]
               },
               model
             )
    end

    test "with one of all supported types with fields" do
      mock_request("boards/widgets/list_all_with_fields.json")

      {:ok, model} = Miro.build(namespace: MyApp, board_id: "o9J_lJibPCc=")

      assert match?(
               %Model{
                 namespace: MyApp,
                 aggregates: [
                   %Aggregate{
                     name: "Aggregate",
                     module: MyApp.Aggregate,
                     commands: [
                       %Command{
                         name: "Command",
                         module: MyApp.Aggregate.Commands.Command,
                         fields: [
                           %Field{name: "Field A", field: :field_a},
                           %Field{name: "Field B", field: :field_b},
                           %Field{name: "Field C", field: :field_c}
                         ]
                       }
                     ],
                     events: [
                       %Event{
                         name: "Event",
                         module: MyApp.Aggregate.Events.Event,
                         fields: [
                           %Field{name: "Field A", field: :field_a},
                           %Field{name: "Field B", field: :field_b},
                           %Field{name: "Field C", field: :field_c}
                         ]
                       }
                     ]
                   }
                 ],
                 event_handlers: [
                   %EventHandler{
                     name: "Event Handler",
                     module: MyApp.Handlers.EventHandler
                   }
                 ],
                 process_managers: [
                   %ProcessManager{
                     name: "Process Manager",
                     module: MyApp.Processes.ProcessManager
                   }
                 ],
                 projections: [
                   %Projection{
                     name: "Projection",
                     module: MyApp.Projections.Projection,
                     fields: [
                       %Field{name: "Field A", field: :field_a},
                       %Field{name: "Field B", field: :field_b},
                       %Field{name: "Field C", field: :field_c}
                     ]
                   }
                 ]
               },
               model
             )
    end

    test "with circular references" do
      mock_request("boards/widgets/list_all_circular_refs.json")

      {:ok, model} = Miro.build(namespace: MyApp, board_id: "o9J_lJibPCc=")

      assert match?(
               %Model{
                 namespace: MyApp,
                 aggregates: [
                   %Aggregate{
                     name: "Aggregate",
                     module: MyApp.Aggregate,
                     commands: [
                       %Command{name: "Command A", module: MyApp.Aggregate.Commands.CommandA},
                       %Command{name: "Command B", module: MyApp.Aggregate.Commands.CommandB}
                     ],
                     events: [
                       %Event{name: "Event A", module: MyApp.Aggregate.Events.EventA},
                       %Event{name: "Event B", module: MyApp.Aggregate.Events.EventB}
                     ]
                   }
                 ],
                 event_handlers: [
                   %EventHandler{
                     name: "Event Handler",
                     module: MyApp.Handlers.EventHandler,
                     events: [
                       %Event{name: "Event A", module: MyApp.Aggregate.Events.EventA},
                       %Event{name: "Event B", module: MyApp.Aggregate.Events.EventB}
                     ]
                   }
                 ],
                 process_managers: [
                   %ProcessManager{
                     name: "Process Manager",
                     module: MyApp.Processes.ProcessManager,
                     events: [
                       %Event{name: "Event A", module: MyApp.Aggregate.Events.EventA},
                       %Event{name: "Event B", module: MyApp.Aggregate.Events.EventB}
                     ]
                   }
                 ],
                 projections: [
                   %Projection{
                     name: "Projection",
                     module: MyApp.Projections.Projection,
                     fields: [],
                     events: [
                       %Event{name: "Event A", module: MyApp.Aggregate.Events.EventA},
                       %Event{name: "Event B", module: MyApp.Aggregate.Events.EventB}
                     ]
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
