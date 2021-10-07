defmodule Commanded.Generator.Source.Miro do
  alias Commanded.Generator.Model

  alias Commanded.Generator.Model.{
    Aggregate,
    Command,
    Event,
    EventHandler,
    ExternalSystem,
    Field,
    ProcessManager,
    Projection
  }

  alias Commanded.Generator.Source
  alias Commanded.Generator.Source.Miro.Client

  @behaviour Source

  def build(opts) do
    namespace = Keyword.fetch!(opts, :namespace)
    board_id = Keyword.fetch!(opts, :board_id)

    client = Client.new()

    with {:ok, widgets} <- Client.list_all_widgets(client, board_id) do
      model =
        Model.new(namespace)
        |> include_aggregates(widgets)
        |> include_events(widgets)
        |> include_event_handlers(widgets)
        |> include_external_systems(widgets)
        |> include_process_managers(widgets)
        |> include_projections(widgets)

      {:ok, model}
    end
  end

  # Include aggregates and their associated commands and events.
  defp include_aggregates(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :aggregate))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, fields} = parse_text(text)

      module = Module.concat([namespace, String.replace(name, " ", "")])

      aggregate =
        case Model.find_aggregate(model, name) do
          %Aggregate{} = aggregate ->
            aggregate

          nil ->
            %Aggregate{name: name, module: module, fields: fields}
        end

      aggregate =
        widgets
        |> connected_to(id, "sticker")
        |> Enum.reduce(aggregate, fn sticker, aggregate ->
          cond do
            is_a?(sticker, :command) ->
              %{"text" => text} = sticker

              {name, fields} = parse_text(text)

              command =
                case Model.find_command(model, module, name) do
                  %Command{} = command -> command
                  nil -> Command.new(Module.concat([module, Commands]), name, fields)
                end

              Aggregate.add_command(aggregate, command)

            is_a?(sticker, :event) ->
              {name, fields} = parse_text(sticker["text"])
              include_aggregate_event(model, aggregate, sticker, widgets, [sticker])

            true ->
              aggregate
          end
        end)

      %Model{aggregates: aggregates} = model

      aggregates =
        Enum.reject(aggregates, fn
          %Aggregate{name: ^name} -> true
          %Aggregate{} -> false
        end)

      %Model{model | aggregates: Enum.sort_by([aggregate | aggregates], & &1.name)}
    end)
  end

  defp include_aggregate_event(
         %Model{} = model,
         %Aggregate{} = aggregate,
         sticker,
         widgets,
         accumulator
       ) do
    %Aggregate{module: module} = aggregate
    %{"id" => id, "text" => text} = sticker

    {name, fields} = parse_text(text)

    event =
      case Model.find_event(model, module, name) do
        %Event{} = event -> event
        nil -> Event.new(Module.concat([module, Events]), name, fields)
      end

    aggregate = Aggregate.add_event(aggregate, event)

    # Include any events connected to this event
    widgets
    |> connected_to(id, "sticker", &is_a?(&1, :event))
    |> Enum.reject(&Enum.member?(accumulator, &1))
    |> Enum.reduce(aggregate, fn sticker, aggregate ->
      include_aggregate_event(model, aggregate, sticker, widgets, [sticker | accumulator])
    end)
  end

  # Include events which aren't produced by an aggregate.
  defp include_events(%Model{} = model, widgets) do
    %Model{events: events, namespace: namespace} = model

    namespace = Module.concat([namespace, Events])

    new_events =
      widgets
      |> typeof("sticker", &is_a?(&1, :event))
      |> Enum.map(fn sticker ->
        %{"text" => text} = sticker

        parse_text(text)
      end)
      |> Enum.reject(fn {name, _fields} ->
        case Model.find_event(model, namespace, name) do
          %Event{} -> true
          nil -> false
        end
      end)
      |> Enum.map(fn {name, fields} ->
        Event.new(namespace, name, fields)
      end)

    %Model{model | events: Enum.sort_by(events ++ new_events, & &1.name)}
  end

  defp include_event_handlers(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :event_handler))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, _fields} = parse_text(text)

      module = Module.concat([namespace, Handlers, String.replace(name, " ", "")])

      event_handler =
        case Model.find_event_handler(model, name) do
          %EventHandler{} = event_handler ->
            event_handler

          nil ->
            %EventHandler{name: name, module: module}
        end

      referenced_events = referenced_events(model, widgets, id)

      event_handler =
        Enum.reduce(referenced_events, event_handler, &EventHandler.add_event(&2, &1))

      Model.add_event_handler(model, event_handler)
    end)
  end

  defp include_external_systems(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :external_system))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, _fields} = parse_text(text)

      module = Module.concat([namespace, ExternalSystems, String.replace(name, " ", "")])

      external_system =
        case Model.find_external_system(model, name) do
          %ExternalSystem{} = external_system ->
            external_system

          nil ->
            %ExternalSystem{name: name, module: module}
        end

      referenced_events = referenced_events(model, widgets, id)

      external_system =
        Enum.reduce(referenced_events, external_system, &ExternalSystem.add_event(&2, &1))

      Model.add_external_system(model, external_system)
    end)
  end

  defp include_process_managers(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :process_manager))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, _fields} = parse_text(text)

      process_manager =
        case Model.find_process_manager(model, name) do
          %ProcessManager{} = process_manager ->
            process_manager

          nil ->
            module = Module.concat([namespace, Processes, String.replace(name, " ", "")])

            %ProcessManager{name: name, module: module}
        end

      referenced_events = referenced_events(model, widgets, id)

      process_manager =
        Enum.reduce(referenced_events, process_manager, &ProcessManager.add_event(&2, &1))

      Model.add_process_manager(model, process_manager)
    end)
  end

  defp include_projections(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    widgets
    |> typeof("sticker", &is_a?(&1, :projection))
    |> Enum.reduce(model, fn sticker, model ->
      %{"id" => id, "text" => text} = sticker

      {name, fields} = parse_text(text)

      projection =
        case Model.find_projection(model, name) do
          %Projection{} = projection ->
            projection

          nil ->
            module = Module.concat([namespace, Projections, String.replace(name, " ", "")])

            %Projection{name: name, module: module, fields: fields}
        end

      referenced_events = referenced_events(model, widgets, id)

      projection = Enum.reduce(referenced_events, projection, &Projection.add_event(&2, &1))

      Model.add_projection(model, projection)
    end)
  end

  defp referenced_events(%Model{} = model, widgets, id) do
    %Model{namespace: namespace} = model

    widgets
    |> connected_to(id, "sticker", &is_a?(&1, :event))
    |> Enum.reduce([], fn sticker, acc ->
      %{"text" => text} = sticker
      {name, _fields} = parse_text(text)
      aggregate_source = connected_to(widgets, sticker["id"], "sticker", &is_a?(&1, :aggregate))

      external_source =
        connected_to(widgets, sticker["id"], "sticker", &is_a?(&1, :external_system))

      # all_sources = connected_to(widgets, sticker["id"], "sticker")

      sources = [{:aggregate, aggregate_source}, {:external_system, external_source}]
      matcher = fn {src, widgets} -> length(widgets) > 0 end

      module =
        case Enum.find(sources, matcher) do
          {:aggregate, [agg]} ->
            {agg_name, _fields} = parse_text(agg["text"])

            case Model.find_aggregate(model, agg_name) do
              %Aggregate{module: module} = aggregate ->
                aggregate

              nil ->
                raise "BOOM can't find aggregate with name: #{agg_name}"
            end

          {:external_system, [ext]} ->
            {ext_name, _fields} = parse_text(ext["text"])

            module = Module.concat([namespace, ExternalSystems, String.replace(name, " ", "")])

          {source, widgets} ->
            raise "Found more than one source for event #{name}"
        end

      case Model.find_event(model, module, name) do
        %Event{} = event -> [event | acc]
        nil -> acc
      end
    end)
  end

  defp is_a?(widget, type)
  defp is_a?(%{"style" => %{"backgroundColor" => "#f5d128"}}, :aggregate), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#a6ccf5"}}, :command), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#ff9d48"}}, :event), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#ea94bb"}}, :event_handler), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#ffcee0"}}, :external_system), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#be88c7"}}, :process_manager), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#d5f692"}}, :projection), do: true
  defp is_a?(_widget, _type), do: false

  # Extract the name and optional fields from a sticker's text.
  defp parse_text(text) do
    parsed = Floki.parse_fragment!(text)

    {name_parts, fields} =
      Enum.reduce(parsed, {[], []}, fn
        {"p", _attrs, [text]}, {name_parts, fields} ->
          case Regex.split(~r/^[^A-Za-z]/, text) do
            [_prefix, name] ->
              name = String.trim(name)
              field = String.replace(name, " ", "") |> Macro.underscore() |> String.to_atom()

              {name_parts, fields ++ [%Field{name: name, field: field}]}

            [name] ->
              name = String.trim(name)

              {name_parts ++ [name], fields}
          end

        {_tag_name, _attrs, _child_nodes}, acc ->
          acc
      end)

    name = Enum.join(name_parts, "")

    {name, fields}
  end

  defp find_by_id(widgets, id) do
    Enum.find(widgets, fn
      %{"id" => ^id} -> true
      _widget -> false
    end)
  end

  defp typeof(widgets, type, filter \\ nil) do
    Enum.filter(widgets, fn
      %{"type" => ^type} = widget -> if is_nil(filter), do: true, else: filter.(widget)
      %{"type" => _type} -> false
    end)
  end

  defp connected_to(widgets, id, type, filter \\ nil) do
    widgets
    |> typeof("line")
    |> Enum.flat_map(fn
      %{"startWidget" => %{"id" => ^id}, "endWidget" => %{"id" => end_id}} -> [end_id]
      %{"startWidget" => %{"id" => start_id}, "endWidget" => %{"id" => ^id}} -> [start_id]
      _line -> []
    end)
    |> Enum.map(&find_by_id(widgets, &1))
    |> typeof(type, filter)
  end
end
