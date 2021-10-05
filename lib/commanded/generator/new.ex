defmodule Commanded.Generator.New do
  @moduledoc false
  use Commanded.Generator

  alias Commanded.Generator.{Model, Project}

  alias Commanded.Generator.Model.{
    Aggregate,
    Command,
    Event,
    EventHandler,
    ExternalSystem,
    ProcessManager,
    Projection
  }

  template(:new, [
    {:eex, "commanded/config/config.exs", :project, "config/config.exs"},
    {:eex, "commanded/config/dev.exs", :project, "config/dev.exs"},
    {:eex, "commanded/config/prod.exs", :project, "config/prod.exs"},
    {:eex, "commanded/config/runtime.exs", :project, "config/runtime.exs"},
    {:eex, "commanded/config/test.exs", :project, "config/test.exs"},
    {:eex, "commanded/lib/app_name/app.ex", :project, "lib/:app/app.ex"},
    {:eex, "commanded/lib/app_name/application.ex", :project, "lib/:app/application.ex"},
    {:eex, "commanded/lib/app_name/event_store.ex", :project, "lib/:app/event_store.ex"},
    {:eex, "commanded/lib/app_name/repo.ex", :project, "lib/:app/repo.ex"},
    {:eex, "commanded/lib/app_name/router.ex", :project, "lib/:app/router.ex"},
    {:eex, "commanded/lib/app_name.ex", :project, "lib/:app.ex"},
    {:eex, "commanded/priv/repo/migrations/create_projection_versions.exs", :project,
     "priv/repo/migrations/:projection_versions_migration_timestamp.exs"},
    {:eex, "commanded/test/test_helper.exs", :project, "test/test_helper.exs"},
    {:eex, "commanded/formatter.exs", :project, ".formatter.exs"},
    {:eex, "commanded/mix.exs", :project, "mix.exs"},
    {:eex, "commanded/README.md", :project, "README.md"}
  ])

  template(:aggregate, [
    {:eex, "aggregate/aggregate.ex", :project, "lib/:app/:aggregate/:aggregate.ex"}
  ])

  template(:command, [
    {:eex, "aggregate/commands/command.ex", :project, "lib/:command_path/:command.ex"}
  ])

  template(:event, [
    {:eex, "aggregate/events/event.ex", :project, "lib/:event_path/:event.ex"}
  ])

  template(:event_handler, [
    {:eex, "event_handler/event_handler.ex", :project, "lib/:app/handlers/:event_handler.ex"}
  ])

  template(:external_system, [
    {:eex, "external_system/external_system.ex", :project,
     "lib/:app/external_systems/:external_system.ex"}
  ])

  template(:process_manager, [
    {:eex, "process_manager/process_manager.ex", :project,
     "lib/:app/processes/:process_manager.ex"}
  ])

  template(:projection, [
    {:eex, "projection/projector.ex", :project, "lib/:app/projections/:projector.ex"},
    {:eex, "projection/projection.ex", :project, "lib/:app/projections/:projection.ex"}
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
    project =
      project
      |> new_project_binding()
      |> Project.put_binding(
        :projection_versions_migration_timestamp,
        timestamp() <> "_create_projection_versions"
      )

    copy_from(project, __MODULE__, :new)

    generate_model(project)
  end

  defp generate_model(%Project{model: nil} = project), do: project

  defp generate_model(%Project{} = project) do
    %Project{
      model: %Model{
        aggregates: aggregates,
        event_handlers: event_handlers,
        external_systems: external_systems,
        process_managers: process_managers,
        projections: projections
      }
    } = project

    for aggregate <- aggregates do
      %Aggregate{commands: commands, events: events} = aggregate

      project = Project.merge_binding(project, aggregate_binding(aggregate))

      copy_from(project, __MODULE__, :aggregate)

      for command <- commands do
        project = Project.merge_binding(project, command_binding(command))

        copy_from(project, __MODULE__, :command)
      end

      for event <- events do
        project = Project.merge_binding(project, event_binding(event))

        copy_from(project, __MODULE__, :event)
      end
    end

    for event_handler <- event_handlers do
      project = Project.merge_binding(project, event_handler_binding(event_handler))

      copy_from(project, __MODULE__, :event_handler)
    end

    for external_system <- external_systems do
      project = Project.merge_binding(project, external_system_binding(external_system))

      copy_from(project, __MODULE__, :external_system)
    end

    for process_manager <- process_managers do
      project = Project.merge_binding(project, process_manager_binding(process_manager))

      copy_from(project, __MODULE__, :process_manager)
    end

    for projection <- projections do
      project = Project.merge_binding(project, projection_binding(projection))

      copy_from(project, __MODULE__, :projection)
    end

    project
  end

  defp new_project_binding(%Project{model: nil} = project) do
    Project.merge_binding(project,
      aggregates: [],
      event_handlers: [],
      external_systems: [],
      process_managers: [],
      projections: []
    )
  end

  defp new_project_binding(%Project{} = project) do
    %Project{
      model: %Model{
        aggregates: aggregates,
        event_handlers: event_handlers,
        external_systems: external_systems,
        process_managers: process_managers,
        projections: projections
      }
    } = project

    Project.merge_binding(project,
      aggregates: Enum.map(aggregates, &Enum.into(aggregate_binding(&1), %{})),
      event_handlers: Enum.map(event_handlers, &Enum.into(event_handler_binding(&1), %{})),
      external_systems: Enum.map(external_systems, &Enum.into(external_system_binding(&1), %{})),
      process_managers: Enum.map(process_managers, &Enum.into(process_manager_binding(&1), %{})),
      projections: Enum.map(projections, &Enum.into(projection_binding(&1), %{}))
    )
  end

  defp aggregate_binding(%Aggregate{} = aggregate) do
    %Aggregate{commands: commands, events: events, module: module, name: name, fields: fields} =
      aggregate

    {namespace, module} = module_parts(module)

    [
      aggregate: Macro.underscore(module),
      aggregate_name: name,
      aggregate_id: ":#{Macro.underscore(module)}_id",
      aggregate_namespace: namespace,
      aggregate_module: module,
      aggregate_prefix: Macro.underscore(module) |> String.replace("_", "-"),
      aggregate_path: Macro.underscore(namespace <> "." <> module),
      commands:
        Enum.map(commands, fn %Command{} = command ->
          %Command{name: name, module: module, fields: fields} = command

          {namespace, module} = module_parts(module)

          %{name: name, module: module, namespace: namespace, fields: fields}
        end),
      events:
        Enum.map(events, fn %Event{} = event ->
          %Event{name: name, module: module, fields: fields} = event

          {namespace, module} = module_parts(module)

          %{name: name, module: module, namespace: namespace, fields: fields}
        end),
      fields: fields
    ]
  end

  defp command_binding(%Command{} = command) do
    %Command{name: name, module: module, fields: fields} = command

    {namespace, module} = module_parts(module)

    [
      command: Macro.underscore(module),
      command_name: name,
      command_module: module,
      command_namespace: namespace,
      command_path: Macro.underscore(namespace),
      fields: fields
    ]
  end

  defp event_binding(%Event{} = event) do
    %Event{name: name, module: module, fields: fields} = event

    {namespace, module} = module_parts(module)

    [
      event: Macro.underscore(module),
      event_name: name,
      event_module: module,
      event_namespace: namespace,
      event_path: Macro.underscore(namespace),
      fields: fields
    ]
  end

  defp event_handler_binding(%EventHandler{} = event_handler) do
    %EventHandler{events: events, module: module, name: name} = event_handler

    {namespace, module} = module_parts(module)

    [
      event_handler: Macro.underscore(module),
      event_handler_name: name,
      event_handler_namespace: namespace,
      event_handler_module: module,
      events:
        Enum.map(events, fn %Event{} = event ->
          %Event{name: name, module: module, fields: fields} = event

          {namespace, module} = module_parts(module)

          %{name: name, module: module, namespace: namespace, fields: fields}
        end)
    ]
  end

  defp external_system_binding(%ExternalSystem{} = external_system) do
    %ExternalSystem{events: events, module: module, name: name} = external_system

    {namespace, module} = module_parts(module)

    [
      external_system: Macro.underscore(module),
      external_system_name: name,
      external_system_namespace: namespace,
      external_system_module: module,
      events:
        Enum.map(events, fn %Event{} = event ->
          %Event{name: name, module: module, fields: fields} = event

          {namespace, module} = module_parts(module)

          %{name: name, module: module, namespace: namespace, fields: fields}
        end)
    ]
  end

  defp process_manager_binding(%ProcessManager{} = process_manager) do
    %ProcessManager{events: events, module: module, name: name} = process_manager

    {namespace, module} = module_parts(module)

    [
      process_manager: Macro.underscore(module),
      process_manager_name: name,
      process_manager_namespace: namespace,
      process_manager_module: module,
      events:
        Enum.map(events, fn %Event{} = event ->
          %Event{name: name, module: module, fields: fields} = event

          {namespace, module} = module_parts(module)

          %{name: name, module: module, namespace: namespace, fields: fields}
        end)
    ]
  end

  defp projection_binding(%Projection{} = projection) do
    %Projection{events: events, module: module, name: name} = projection

    {namespace, module} = module_parts(module)

    projector_module = "#{module}Projector"

    [
      projection: Macro.underscore(module),
      projection_name: name,
      projection_namespace: namespace,
      projection_module: module,
      projection_table: Macro.underscore(module),
      projector: Macro.underscore(projector_module),
      projector_module: projector_module,
      events:
        Enum.map(events, fn %Event{} = event ->
          %Event{name: name, module: module, fields: fields} = event

          {namespace, module} = module_parts(module)

          %{name: name, module: module, namespace: namespace, fields: fields}
        end)
    ]
  end

  defp module_parts(module) do
    {namespace, [module]} = Module.split(module) |> Enum.split(-1)

    namespace = Enum.join(namespace, ".")

    {namespace, module}
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
