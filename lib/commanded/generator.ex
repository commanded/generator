defmodule Commanded.Generator do
  @moduledoc false
  import Mix.Generator

  alias Commanded.Generator.Project

  @commanded Path.expand("../..", __DIR__)
  @commanded_version Version.parse!(Mix.Project.config()[:version])

  @callback prepare_project(Project.t()) :: Project.t()
  @callback generate(Project.t()) :: Project.t()

  defmacro __using__(_env) do
    quote do
      @behaviour unquote(__MODULE__)
      import Mix.Generator
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :templates, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    root = Path.expand("../../templates", __DIR__)

    templates_ast =
      for {name, mappings} <- Module.get_attribute(env.module, :templates) do
        for {format, source, _, _} <- mappings, format != :keep do
          path = Path.join(root, source)

          if format in [:config, :prod_config, :eex] do
            compiled = EEx.compile_file(path)

            quote do
              @external_resource unquote(path)
              @file unquote(path)
              def render(unquote(name), unquote(source), var!(assigns))
                  when is_list(var!(assigns)),
                  do: unquote(compiled)
            end
          else
            quote do
              @external_resource unquote(path)
              def render(unquote(name), unquote(source), _assigns), do: unquote(File.read!(path))
            end
          end
        end
      end

    quote do
      unquote(templates_ast)
      def template_files(name), do: Keyword.fetch!(@templates, name)
    end
  end

  defmacro template(name, mappings) do
    quote do
      @templates {unquote(name), unquote(mappings)}
    end
  end

  def copy_from(%Project{} = project, mod, name) when is_atom(name) do
    mapping = mod.template_files(name)

    for {format, source, project_location, target_path} <- mapping do
      target = Project.join_path(project, project_location, target_path)

      case format do
        :keep ->
          File.mkdir_p!(target)

        :text ->
          create_file(target, mod.render(name, source, project.binding))

        :config ->
          contents = mod.render(name, source, project.binding)
          config_inject(Path.dirname(target), Path.basename(target), contents)

        :prod_config ->
          contents = mod.render(name, source, project.binding)
          prod_only_config_inject(Path.dirname(target), Path.basename(target), contents)

        :eex ->
          contents = mod.render(name, source, project.binding)
          create_file(target, contents)
      end
    end
  end

  def config_inject(path, file, to_inject) do
    file = Path.join(path, file)

    contents =
      case File.read(file) do
        {:ok, bin} -> bin
        {:error, _} -> "import Config\n"
      end

    with :error <- split_with_self(contents, "use Mix.Config\n"),
         :error <- split_with_self(contents, "import Config\n") do
      Mix.raise(~s[Could not find "use Mix.Config" or "import Config" in #{inspect(file)}])
    else
      [left, middle, right] ->
        write_formatted!(file, [left, middle, ?\n, to_inject, ?\n, right])
    end
  end

  def prod_only_config_inject(path, file, to_inject) do
    file = Path.join(path, file)

    contents =
      case File.read(file) do
        {:ok, bin} ->
          bin

        {:error, _} ->
          """
            import Config

            if config_env() == :prod do
            end
          """
      end

    case split_with_self(contents, "if config_env() == :prod do") do
      [left, middle, right] ->
        write_formatted!(file, [left, middle, ?\n, to_inject, ?\n, right])

      :error ->
        Mix.raise(~s[Could not find "if config_env() == :prod do" in #{inspect(file)}])
    end
  end

  defp write_formatted!(file, contents) do
    formatted = contents |> IO.iodata_to_binary() |> Code.format_string!()
    File.write!(file, [formatted, ?\n])
  end

  defp split_with_self(contents, text) do
    case :binary.split(contents, text) do
      [left, right] -> [left, text, right]
      [_] -> :error
    end
  end

  def put_binding(%Project{opts: opts} = project) do
    dev = Keyword.get(opts, :dev, false)
    commanded_path = commanded_path(project, dev)

    version = @commanded_version

    binding = [
      elixir_version: elixir_version(),
      app_name: project.app,
      app_module: inspect(project.app_mod),
      root_app_name: project.root_app,
      root_app_module: inspect(project.root_mod),
      commanded_application_module: inspect(Module.concat(project.app_mod, App)),
      commanded_router_module: inspect(Module.concat(project.app_mod, Router)),
      commanded_github_version_tag: "v#{version.major}.#{version.minor}",
      commanded_dep: commanded_dep(commanded_path, version),
      commanded_path: commanded_path,
      generators: nil_if_empty(project.generators),
      namespaced?: namespaced?(project)
    ]

    %Project{project | binding: binding}
  end

  defp elixir_version do
    System.version()
  end

  defp namespaced?(project) do
    Macro.camelize(project.app) != inspect(project.app_mod)
  end

  defp nil_if_empty([]), do: nil
  defp nil_if_empty(other), do: other

  defp commanded_path(%Project{} = project, true) do
    absolute = Path.expand(project.project_path)
    relative = Path.relative_to(absolute, @commanded)

    if absolute == relative do
      Mix.raise("--dev projects must be generated inside Commanded directory")
    end

    project
    |> commanded_path_prefix()
    |> Path.join(relative)
    |> Path.split()
    |> Enum.map(fn _ -> ".." end)
    |> Path.join()
  end

  defp commanded_path(%Project{}, false), do: "deps/commanded"

  defp commanded_path_prefix(%Project{}), do: ".."

  defp commanded_dep("deps/commanded", %{pre: ["dev"]}),
    do: ~s[{:commanded, github: "commanded/commanded", override: true}]

  defp commanded_dep("deps/commanded", version),
    do: ~s[{:commanded, "~> #{version}"}]

  defp commanded_dep(path, _version),
    do: ~s[{:commanded, path: #{inspect(path)}, override: true}]
end
