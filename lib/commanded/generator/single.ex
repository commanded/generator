defmodule Commanded.Generator.Single do
  @moduledoc false
  use Commanded.Generator

  alias Commanded.Generator.Project

  template(:new, [
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
