defmodule Commanded.Generator.Source.Miro do
  alias Commanded.Generator.Model
  alias Commanded.Generator.Model.{Aggregate, Command, Event}
  alias Commanded.Generator.Source
  alias Commanded.Generator.Source.Miro.Client

  @behaviour Source

  def build(opts) do
    namespace = Keyword.fetch!(opts, :namespace)
    board_id = Keyword.fetch!(opts, :board_id)

    client = Client.new()

    with {:ok, widgets} <- Client.list_all_widgets(client, board_id) do
      model =
        %Model{namespace: namespace}
        |> include_aggregates(widgets)
        |> include_events(widgets)

      {:ok, model}
    end
  end

  defp include_aggregates(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    aggregates =
      widgets
      |> typeof("sticker")
      |> Enum.filter(&is_a?(&1, :aggregate))
      |> Enum.map(fn sticker ->
        %{"id" => id, "text" => text} = sticker

        name = Floki.parse_fragment!(text) |> Floki.text()
        module = Module.concat([namespace, String.replace(name, " ", "")])

        {commands, events} =
          widgets
          |> typeof("line")
          |> connected_to(id)
          |> Enum.map(&find_by_id(widgets, &1))
          |> typeof("sticker")
          |> Enum.reduce({[], []}, fn sticker, {commands, events} = acc ->
            cond do
              is_a?(sticker, :command) ->
                command = build_command(sticker, namespace)

                {[command | commands], events}

              is_a?(sticker, :event) ->
                event = build_event(sticker, namespace)

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

    %Model{model | aggregates: aggregates}
  end

  defp is_a?(widget, type)
  defp is_a?(%{"style" => %{"backgroundColor" => "#f5d128"}}, :aggregate), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#a6ccf5"}}, :command), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#ff9d48"}}, :event), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#ea94bb"}}, :event_handler), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#be88c7"}}, :process_manager), do: true
  defp is_a?(%{"style" => %{"backgroundColor" => "#d5f692"}}, :projection), do: true
  defp is_a?(_widget, _type), do: false

  defp include_events(%Model{} = model, widgets) do
    %Model{namespace: namespace} = model

    events =
      widgets
      |> typeof("sticker")
      |> Enum.filter(&is_a?(&1, :event))
      |> Enum.map(&build_event(&1, namespace))

    %Model{model | events: events}
  end

  defp build_command(widget, namespace) do
    %{"text" => text} = widget

    name = Floki.parse_fragment!(text) |> Floki.text()
    module = Module.concat([namespace, String.replace(name, " ", "")])

    %Command{
      name: name,
      module: module
    }
  end

  defp build_event(widget, namespace) do
    %{"text" => text} = widget

    name = Floki.parse_fragment!(text) |> Floki.text()
    module = Module.concat([namespace, String.replace(name, " ", "")])

    %Event{
      name: name,
      module: module
    }
  end

  defp find_by_id(widgets, id) do
    Enum.find(widgets, fn
      %{"id" => ^id} -> true
      _widget -> false
    end)
  end

  defp typeof(widgets, type) do
    Enum.filter(widgets, fn
      %{"type" => ^type} -> true
      %{"type" => _type} -> false
    end)
  end

  defp connected_to(widgets, id) do
    Enum.flat_map(widgets, fn
      %{"startWidget" => %{"id" => ^id}, "endWidget" => %{"id" => end_id}} -> [end_id]
      %{"startWidget" => %{"id" => start_id}, "endWidget" => %{"id" => ^id}} -> [start_id]
      _line -> []
    end)
  end
end
