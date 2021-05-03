defmodule Commanded.Generator.Project do
  @moduledoc false
  alias Commanded.Generator.Project

  defstruct base_path: nil,
            app: nil,
            app_mod: nil,
            app_path: nil,
            root_app: nil,
            root_mod: nil,
            project_path: nil,
            opts: :unset,
            binding: [],
            generators: [],
            model: nil

  def new(project_path, opts) do
    project_path = Path.expand(project_path)
    app = opts[:app] || Path.basename(project_path)
    app_mod = Module.concat([opts[:module] || Macro.camelize(app)])

    %Project{
      base_path: project_path,
      app: app,
      app_mod: app_mod,
      root_app: app,
      root_mod: app_mod,
      opts: opts
    }
  end

  def verbose?(%Project{opts: opts}) do
    Keyword.get(opts, :verbose, false)
  end

  def merge_binding(%Project{} = project, new_binding) do
    %Project{binding: binding} = project

    %Project{project | binding: Keyword.merge(binding, new_binding)}
  end

  def build_model(%Project{} = project, source, args) do
    {:ok, model} = source.build(args)

    %Project{project | model: model}
  end

  def join_path(%Project{} = project, location, path) when location in [:project, :app] do
    project
    |> Map.fetch!(:"#{location}_path")
    |> Path.join(path)
    |> expand_path_with_bindings(project)
  end

  defp expand_path_with_bindings(path, %Project{} = project) do
    %Project{binding: binding} = project

    Regex.replace(Regex.recompile!(~r/:[a-zA-Z0-9_]+/), path, fn ":" <> key, _ ->
      value = Map.get(project, :"#{key}") || Keyword.get(binding, :"#{key}")

      to_string(value)
    end)
  end
end
