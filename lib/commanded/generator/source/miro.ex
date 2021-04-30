defmodule Commanded.Generator.Source.Miro do
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
        |> include_process_managers(widgets)
        |> include_projections(widgets)

      {:ok, model}
    end
  end

  # Include aggregates and their associated commands and events.
  defp include_aggregates(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    aggregates =
      widgets
      |> typeof("sticker", &is_a?(&1, :aggregate))
      |> Enum.map(fn sticker ->
        %{"id" => id, "text" => text} = sticker

        {name, _fields} = parse_text(text)

        module = Module.concat([namespace, String.replace(name, " ", "")])

        {commands, events} =
          widgets
          |> connected_to(id, "sticker")
          |> Enum.reduce({[], []}, fn sticker, {commands, events} = acc ->
            cond do
              is_a?(sticker, :command) ->
                command = build_command(sticker, Module.concat([module, Commands]))

                {[command | commands], events}

              is_a?(sticker, :event) ->
                event = build_event(sticker, Module.concat([module, Events]))

                {commands, [event | events]}

              true ->
                acc
            end
          end)

        %Aggregate{
          name: name,
          module: module,
          commands: commands,
          events: events
        }
      end)

    events = Enum.flat_map(aggregates, fn %Aggregate{events: events} -> events end)

    %Model{model | aggregates: aggregates, events: events}
  end

  # Include events which aren't produced by an aggregate.
  defp include_events(%Model{} = model, widgets) do
    %Model{events: events, namespace: namespace} = model

    new_events =
      widgets
      |> typeof("sticker", &is_a?(&1, :event))
      |> Enum.reject(fn sticker ->
        %{"id" => id} = sticker

        case Model.find_event(model, id) do
          %Event{} -> true
          nil -> false
        end
      end)
      |> Enum.map(&build_event(&1, Module.concat([namespace, Events])))

    %Model{model | events: events ++ new_events}
  end

  defp include_event_handlers(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    event_handlers =
      widgets
      |> typeof("sticker", &is_a?(&1, :event_handler))
      |> Enum.map(fn sticker ->
        %{"id" => id, "text" => text} = sticker

        {name, _fields} = parse_text(text)

        module = Module.concat([namespace, Handlers, String.replace(name, " ", "")])
        events = referenced_events(model, widgets, id)

        %EventHandler{name: name, module: module, events: events}
      end)

    %Model{model | event_handlers: event_handlers}
  end

  defp include_process_managers(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    process_managers =
      widgets
      |> typeof("sticker", &is_a?(&1, :process_manager))
      |> Enum.map(fn sticker ->
        %{"id" => id, "text" => text} = sticker

        {name, _fields} = parse_text(text)

        module = Module.concat([namespace, Processes, String.replace(name, " ", "")])
        events = referenced_events(model, widgets, id)

        %ProcessManager{name: name, module: module, events: events}
      end)

    %Model{model | process_managers: process_managers}
  end

  defp include_projections(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    projections =
      widgets
      |> typeof("sticker", &is_a?(&1, :projection))
      |> Enum.map(fn sticker ->
        %{"id" => id, "text" => text} = sticker

        {name, fields} = parse_text(text)

        module = Module.concat([namespace, Projections, String.replace(name, " ", "")])
        events = referenced_events(model, widgets, id)

        %Projection{name: name, module: module, events: events, fields: fields}
      end)

    %Model{model | projections: projections}
  end

  defp referenced_events(%Model{} = model, widgets, id) do
    widgets
    |> connected_to(id, "sticker", &is_a?(&1, :event))
    |> Enum.reduce([], fn sticker, acc ->
      %{"id" => id} = sticker

      case Model.find_event(model, id) do
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
  defp is_a?(%{"style" => %{"backgroundColor" => "#be88c7"}}, :process_manager), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#d5f692"}}, :projection), do: true
  defp is_a?(_widget, _type), do: false

  defp build_command(widget, namespace) do
    %{"id" => id, "text" => text} = widget

    {name, fields} = parse_text(text)

    module = Module.concat([namespace, String.replace(name, " ", "")])

    %Command{id: id, name: name, module: module, fields: fields}
  end

  defp build_event(widget, namespace) do
    %{"id" => id, "text" => text} = widget

    {name, fields} = parse_text(text)

    module = Module.concat([namespace, String.replace(name, " ", "")])

    %Event{id: id, name: name, module: module, fields: fields}
  end

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
