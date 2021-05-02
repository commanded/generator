Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Commanded.NewTest do
  use ExUnit.Case, async: false

  import MixHelper
  import ExUnit.CaptureIO
  import Tesla.Mock

  setup do
    send(self(), {:mix_shell_input, :yes?, false})

    :ok
  end

  test "returns the version" do
    Mix.Tasks.Commanded.New.run(["-v"])
    assert_received {:mix_shell, :info, ["Commanded installer v" <> _]}
  end

  test "new with defaults" do
    in_tmp("new with defaults", fn ->
      Mix.Tasks.Commanded.New.run(["my_app"])

      assert_commanded_application_files()

      # Install dependencies?
      assert_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}

      # Instructions
      assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
      assert msg =~ "$ cd my_app"
      assert msg =~ "$ mix deps.get"

      assert_received {:mix_shell, :info, ["You can run your app" <> _]}
    end)
  end

  test "new with invalid args" do
    assert_raise Mix.Error, ~r"Application name must start with a letter and ", fn ->
      Mix.Tasks.Commanded.New.run(["007invalid"])
    end

    assert_raise Mix.Error, ~r"Application name must start with a letter and ", fn ->
      Mix.Tasks.Commanded.New.run(["valid", "--app", "007invalid"])
    end

    assert_raise Mix.Error, ~r"Module name must be a valid Elixir alias", fn ->
      Mix.Tasks.Commanded.New.run(["valid", "--module", "not.valid"])
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Commanded.New.run(["string"])
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Commanded.New.run(["valid", "--app", "mix"])
    end

    assert_raise Mix.Error, ~r"Module name \w+ is already taken", fn ->
      Mix.Tasks.Commanded.New.run(["valid", "--module", "String"])
    end
  end

  test "invalid options" do
    assert_raise Mix.Error, ~r/Invalid option: -d/, fn ->
      Mix.Tasks.Commanded.New.run(["valid", "-database", "mysql"])
    end
  end

  test "new without args" do
    in_tmp("new without args", fn ->
      assert capture_io(fn -> Mix.Tasks.Commanded.New.run([]) end) =~
               "Creates a new Commanded project."
    end)
  end

  test "new imported from Miro" do
    mock_miro_request("boards/widgets/list_all_conference_example.json")

    in_tmp("new from Miro", fn ->
      Mix.Tasks.Commanded.New.run(["my_app", "--miro", "o9J_lJibPCc="])

      assert_commanded_application_files()

      # Aggregates
      assert_file("my_app/lib/my_app/conference/conference.ex", fn file ->
        assert file =~ "defmodule MyApp.Conference do"
        assert file =~ "Conference aggregate"
        assert file =~ "def execute(%Conference{} = conference, %CreateConference{} = command) do"
      end)

      assert_file("my_app/lib/my_app/order/order.ex", fn file ->
        assert file =~ "defmodule MyApp.Order do"
        assert file =~ "Order aggregate"
        assert file =~ "alias MyApp.Order.Commands.RegisterToConference"
        assert file =~ "alias MyApp.Order.Events.OrderPlaced"
        assert file =~ "def apply(%Order{} = order, %OrderPlaced{} = event) do"
      end)

      # Install dependencies?
      assert_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}

      # Instructions
      assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
      assert msg =~ "$ cd my_app"
      assert msg =~ "$ mix deps.get"

      assert_received {:mix_shell, :info, ["You can run your app" <> _]}
    end)
  end

  defp assert_commanded_application_files do
    assert_file("my_app/README.md")

    assert_file("my_app/.formatter.exs", fn file ->
      assert file =~ "import_deps: [:commanded]"
      assert file =~ "inputs: [\"*.{ex,exs}\", \"{config,lib,test}/**/*.{ex,exs}\"]"
    end)

    assert_file("my_app/mix.exs", fn file ->
      assert file =~ "app: :my_app"
      refute file =~ "deps_path: \"../../deps\""
      refute file =~ "lockfile: \"../../mix.lock\""
    end)

    # Configuration files
    assert_file("my_app/config/config.exs", fn file ->
      assert file =~ "config :my_app, event_stores: [MyApp.EventStore]"
    end)

    assert_file("my_app/config/dev.exs")
    assert_file("my_app/config/prod.exs")
    assert_file("my_app/config/runtime.exs")
    assert_file("my_app/config/test.exs")

    # Elixir Application module
    assert_file("my_app/lib/my_app/application.ex", ~r/defmodule MyApp.Application do/)

    # Commanded Application module
    assert_file("my_app/lib/my_app/app.ex", fn file ->
      assert file =~ "defmodule MyApp.App do"
      assert file =~ "use Commanded.Application,\n    otp_app: :my_app"
      assert file =~ "router(MyApp.Router)"
    end)

    # Commanded Router module
    assert_file("my_app/lib/my_app/router.ex", fn file ->
      assert file =~ "defmodule MyApp.Router do"
      assert file =~ "use Commanded.Commands.Router"
    end)

    # Eventstore module
    assert_file("my_app/lib/my_app/event_store.ex", fn file ->
      assert file =~ "defmodule MyApp.EventStore do"
      assert file =~ "use EventStore,\n    otp_app: :my_app"
    end)

    assert_file("my_app/lib/my_app.ex", ~r/defmodule MyApp do/)

    assert_file("my_app/mix.exs", fn file ->
      assert file =~ "mod: {MyApp.Application, []}"
      assert file =~ "{:jason, \"~> 1.2\"}"
      assert file =~ "{:commanded,"
      assert file =~ "{:commanded_eventstore_adapter,"
      assert file =~ "{:eventstore,"
    end)

    assert_file("my_app/test/test_helper.exs")
  end

  defp mock_miro_request(path) do
    mock(fn
      %{method: :get, url: "https://api.miro.com/v1/boards/o9J_lJibPCc=/widgets/"} ->
        %Tesla.Env{
          status: 200,
          headers: [{"content-type", "application/json"}],
          body: File.read!(Path.absname("../../fixtures/miro/" <> path, __DIR__))
        }
    end)
  end
end
