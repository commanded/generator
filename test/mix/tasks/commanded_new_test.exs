Code.require_file("../../mix_helper.exs", __DIR__)

defmodule Mix.Tasks.Commanded.NewTest do
  use ExUnit.Case, async: false

  import MixHelper
  import ExUnit.CaptureIO

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

      assert_file("my_app/README.md")

      # assert_file("phx_blog/.formatter.exs", fn file ->
      #   assert file =~ "import_deps: [:ecto, :commanded]"
      #
      #   assert file =~
      #            "inputs: [\"*.{ex,exs}\", \"priv/*/seeds.exs\", \"{config,lib,test}/**/*.{ex,exs}\"]"
      #
      #   assert file =~ "subdirectories: [\"priv/*/migrations\"]"
      # end)

      assert_file("my_app/mix.exs", fn file ->
        assert file =~ "app: :my_app"
        refute file =~ "deps_path: \"../../deps\""
        refute file =~ "lockfile: \"../../mix.lock\""
      end)

      # assert_file("phx_blog/config/config.exs", fn file ->
      #   assert file =~ "ecto_repos: [PhxBlog.Repo]"
      #   assert file =~ "config :commanded, :json_library, Jason"
      #   refute file =~ "namespace: PhxBlog"
      #   refute file =~ "config :phx_blog, :generators"
      # end)
      #
      # assert_file("phx_blog/config/prod.exs")
      # assert_file("phx_blog/config/runtime.exs")
      #
      # assert_file("phx_blog/lib/phx_blog/application.ex", ~r/defmodule PhxBlog.Application do/)
      # assert_file("phx_blog/lib/phx_blog.ex", ~r/defmodule PhxBlog do/)
      #
      # assert_file("phx_blog/mix.exs", fn file ->
      #   assert file =~ "mod: {PhxBlog.Application, []}"
      #   assert file =~ "{:jason, \"~> 1.0\"}"
      #   assert file =~ "{:phoenix_live_dashboard,"
      # end)
      #
      # assert_file("phx_blog/test/test_helper.exs")
      #
      # assert_file(
      #   "phx_blog/lib/phx_blog_web/controllers/page_controller.ex",
      #   ~r/defmodule PhxBlogWeb.PageController/
      # )
      #
      # assert_file(
      #   "phx_blog/lib/phx_blog_web/views/page_view.ex",
      #   ~r/defmodule PhxBlogWeb.PageView/
      # )
      #
      # assert_file("phx_blog/lib/phx_blog_web/router.ex", fn file ->
      #   assert file =~ "defmodule PhxBlogWeb.Router"
      #   assert file =~ "live_dashboard"
      #   assert file =~ "import Phoenix.LiveDashboard.Router"
      # end)
      #
      # assert_file("phx_blog/lib/phx_blog_web/endpoint.ex", fn file ->
      #   assert file =~ ~s|defmodule PhxBlogWeb.Endpoint|
      #   assert file =~ ~s|socket "/live"|
      #   assert file =~ ~s|plug Phoenix.LiveDashboard.RequestLogger|
      # end)
      #
      # assert_file("phx_blog/config/dev.exs", fn file ->
      #   assert file =~ "watchers: [\n    node:"
      #   assert file =~ "lib/phx_blog_web/(live|views)/.*(ex)"
      #   assert file =~ "lib/phx_blog_web/templates/.*(eex)"
      # end)
      #
      # # Install dependencies?
      # assert_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}
      #
      # # Instructions
      # assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
      # assert msg =~ "$ cd phx_blog"
      # assert msg =~ "$ mix deps.get"
      #
      # # assert_received {:mix_shell, :info, ["Then configure your database in config/dev.exs" <> _]}
      # assert_received {:mix_shell, :info, ["Start your Commanded app" <> _]}
    end)
  end

  # test "new without defaults" do
  #   in_tmp("new without defaults", fn ->
  #     Mix.Tasks.Phx.New.run([@app_name, "--no-projections"])
  #
  #     # No read model projections
  #     # config = ~r/config :phx_blog, PhxBlog.Repo,/
  #     # refute File.exists?("phx_blog/lib/phx_blog/repo.ex")
  #   end)
  # end

  # test "new with binary_id" do
  #   in_tmp("new with binary_id", fn ->
  #     Mix.Tasks.Phx.New.run([@app_name, "--binary-id"])
  #     assert_file("phx_blog/config/config.exs", ~r/generators: \[binary_id: true\]/)
  #   end)
  # end

  # test "new with uppercase" do
  #   in_tmp("new with uppercase", fn ->
  #     Mix.Tasks.Phx.New.run(["phxBlog"])
  #
  #     assert_file("phxBlog/README.md")
  #
  #     assert_file("phxBlog/mix.exs", fn file ->
  #       assert file =~ "app: :phxBlog"
  #     end)
  #
  #     assert_file("phxBlog/config/dev.exs", fn file ->
  #       assert file =~ ~r/config :phxBlog, PhxBlog.Repo,/
  #       assert file =~ "database: \"phxblog_dev\""
  #     end)
  #   end)
  # end

  # test "new with path, app and module" do
  #   in_tmp("new with path, app and module", fn ->
  #     project_path = Path.join(File.cwd!(), "custom_path")
  #     Mix.Tasks.Phx.New.run([project_path, "--app", @app_name, "--module", "PhoteuxBlog"])
  #
  #     assert_file("custom_path/.gitignore")
  #     assert_file("custom_path/.gitignore", ~r/\n$/)
  #     assert_file("custom_path/mix.exs", ~r/app: :phx_blog/)
  #     assert_file("custom_path/lib/phx_blog_web/endpoint.ex", ~r/app: :phx_blog/)
  #     assert_file("custom_path/config/config.exs", ~r/namespace: PhoteuxBlog/)
  #
  #     assert_file(
  #       "custom_path/lib/phx_blog_web.ex",
  #       ~r/use Phoenix.Controller, namespace: PhoteuxBlogWeb/
  #     )
  #   end)
  # end

  # test "new with --no-install" do
  #   in_tmp("new with no install", fn ->
  #     Mix.Tasks.Phx.New.run([@app_name, "--no-install"])
  #
  #     # Does not prompt to install dependencies
  #     refute_received {:mix_shell, :yes?, ["\nFetch and install dependencies?"]}
  #
  #     # Instructions
  #     assert_received {:mix_shell, :info, ["\nWe are almost there" <> _ = msg]}
  #     assert msg =~ "$ cd phx_blog"
  #     assert msg =~ "$ mix deps.get"
  #
  #     assert_received {:mix_shell, :info, ["Then configure your database in config/dev.exs" <> _]}
  #     assert_received {:mix_shell, :info, ["Start your Phoenix app" <> _]}
  #   end)
  # end

  # test "new defaults to pg adapter" do
  #   in_tmp("new defaults to pg adapter", fn ->
  #     project_path = Path.join(File.cwd!(), "custom_path")
  #     Mix.Tasks.Phx.New.run([project_path])
  #
  #     assert_file("custom_path/mix.exs", ":postgrex")
  #
  #     assert_file("custom_path/config/dev.exs", [
  #       ~r/username: "postgres"/,
  #       ~r/password: "postgres"/,
  #       ~r/hostname: "localhost"/
  #     ])
  #
  #     assert_file("custom_path/config/test.exs", [
  #       ~r/username: "postgres"/,
  #       ~r/password: "postgres"/,
  #       ~r/hostname: "localhost"/
  #     ])
  #
  #     assert_file("custom_path/config/runtime.exs", [~r/url: database_url/])
  #     assert_file("custom_path/lib/custom_path/repo.ex", "Ecto.Adapters.Postgres")
  #
  #     assert_file(
  #       "custom_path/test/support/conn_case.ex",
  #       "Ecto.Adapters.SQL.Sandbox.start_owner"
  #     )
  #
  #     assert_file(
  #       "custom_path/test/support/channel_case.ex",
  #       "Ecto.Adapters.SQL.Sandbox.start_owner"
  #     )
  #
  #     assert_file(
  #       "custom_path/test/support/data_case.ex",
  #       "Ecto.Adapters.SQL.Sandbox.start_owner"
  #     )
  #   end)
  # end

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
end
