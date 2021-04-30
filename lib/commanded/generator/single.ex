defmodule Commanded.Generator.Single do
  @moduledoc false
  use Commanded.Generator

  alias Commanded.Generator.Project

  template(:new, [
    {:eex, "commanded/config/config.exs", :project, "config/config.exs"},
    {:eex, "commanded/config/dev.exs", :project, "config/dev.exs"},
    {:eex, "commanded/config/prod.exs", :project, "config/prod.exs"},
    {:eex, "commanded/config/runtime.exs", :project, "config/runtime.exs"},
    {:eex, "commanded/config/test.exs", :project, "config/test.exs"},
    {:eex, "commanded/lib/app_name/app.ex", :project, "lib/:app/app.ex"},
    {:eex, "commanded/lib/app_name/application.ex", :project, "lib/:app/application.ex"},
    {:eex, "commanded/lib/app_name/event_store.ex", :project, "lib/:app/event_store.ex"},
    {:eex, "commanded/lib/app_name/router.ex", :project, "lib/:app/router.ex"},
    {:eex, "commanded/lib/app_name.ex", :project, "lib/:app.ex"},
    {:eex, "commanded/test/test_helper.exs", :project, "test/test_helper.exs"},
    {:eex, "commanded/formatter.exs", :project, ".formatter.exs"},
    {:eex, "commanded/mix.exs", :project, "mix.exs"},
    {:eex, "commanded/README.md", :project, "README.md"}
  ])

  def prepare_project(%Project{app: app} = project) when not is_nil(app) do
    %Project{project | project_path: project.base_path}
    |> put_app()
    |> put_root_app()
  end

  defp put_app(%Project{base_path: base_path} = project) do
    %Project{project | app_path: base_path}
  end

  defp put_root_app(%Project{app: app, opts: opts} = project) do
    %Project{
      project
      | root_app: app,
        root_mod: Module.concat([opts[:module] || Macro.camelize(app)])
    }
  end

  def generate(%Project{} = project) do
    copy_from(project, __MODULE__, :new)

    project
  end
end
