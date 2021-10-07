defmodule Commanded.Generator.Source.Miro.Graph do
  # serial events?
  alias Commanded.Generator.Source.Miro.Client

  @outs %{
    aggregate: [:event],
    command: [:aggregate],
    event: [:event_handler, :external_system, :process_manager, :projection],
    event_handler: [:command, :event],
    external_system: [:command, :event],
    process_manager: [:command],
    projection: [:external_system]
  }

  @ins @outs
       |> Enum.flat_map(fn {value, keys} -> Enum.map(keys, &{&1, value}) end)
       |> Enum.group_by(fn {k, _} -> k end, fn {_, v} -> v end)

  # "#f16c7f" => :red
  # "#ffcee0" => :light_pink
  @nodes %{
    aggregate: %{
      color: "#f5d128",
      expected_in: :one_or_more,
      expected_out: :one_or_more,
      possible_outs: @outs[:aggregate],
      possible_ins: @ins[:aggregate]
    },
    command: %{
      color: "#a6ccf5",
      expected_in: :maybe_one_or_more,
      expected_out: :only_one,
      possible_outs: @outs[:command],
      possible_ins: @ins[:command]
    },
    event: %{
      color: "#ff9d48",
      expected_in: :only_one,
      expected_out: :maybe_one_or_more,
      possible_outs: @outs[:event],
      possible_ins: @ins[:event]
    },
    event_handler: %{
      color: "#ea94bb",
      expected_in: :one_or_more,
      expected_out: :maybe_one_or_more,
      possible_outs: @outs[:event_handler],
      possible_ins: @ins[:event_handler]
    },
    external_system: %{
      color: "#f5f6f8",
      expected_in: :maybe_one_or_more,
      expected_out: :maybe_one_or_more,
      possible_outs: @outs[:external_system],
      possible_ins: @ins[:external_system]
    },
    process_manager: %{
      color: "#be88c7",
      expected_in: :one_or_more,
      expected_out: :one_or_more,
      possible_outs: @outs[:process_manager],
      possible_ins: @ins[:process_manager]
    },
    projection: %{
      color: "#d5f692",
      expected_in: :one_or_more,
      expected_out: :none,
      possible_outs: @outs[:projection],
      possible_ins: @ins[:projection]
    }
  }

  @stickers Enum.into(@nodes, %{}, fn {k, v} -> {v.color, k} end)
  @node_types Map.keys(@nodes)

  def build_raw_graph(board) do
    {:ok, stickers} = Client.new() |> Client.list_all_widgets(board, widgetType: "sticker")
    {:ok, lines} = Client.new() |> Client.list_all_widgets(board, widgetType: "line")

    Graph.new()
    |> graph_reduce(stickers, fn sticker, acc ->
      id = id(sticker)

      metadata = %{
        position: position(sticker),
        text: text(sticker),
        type: @stickers[color(sticker)]
      }

      Graph.add_vertex(acc, id, metadata)
    end)
    |> graph_reduce(lines, fn line, acc ->
      Graph.add_edge(acc, start(line), finish(line))
    end)
  end

  def build_graph(g) do
    new_g = messy_add(Graph.new(), g)

    map = id_to_title_map(new_g)

    add_title_edges(g, new_g, map)
  end

  defp messy_add(g, orig_g) do
    Graph.Reducers.Dfs.reduce(orig_g, g, fn vertex_id, new_g ->
      [metadata] = Graph.vertex_labels(orig_g, vertex_id)

      # These two need to find their namespace
      new_metadata =
        if (t = metadata.type) in [:command, :event] do
          node = @nodes[t]
          edges = Graph.edges(orig_g, vertex_id)

          edges
          |> Enum.map(fn edge ->
            cond do
              edge.v1 == vertex_id ->
                av2 = augment_vertex(orig_g, edge.v2)
                if av2.type in node.possible_outs, do: {:out, av2}

              edge.v2 == vertex_id ->
                av1 = augment_vertex(orig_g, edge.v1)
                if av1.type in node.possible_ins, do: {:in, av1}

              true ->
                raise "wtf"
            end
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.sort_by(fn {_, a} -> a.type end)
          |> case do
            [{_, one} | _] ->
              Map.put(
                metadata,
                :namespace,
                "#{Macro.camelize(Atom.to_string(metadata.type))}.#{parse_text(one.text)}"
              )

            _ ->
              raise("#{inspect(metadata)} has no possible ins/outs")
          end
        else
          Map.put(metadata, :namespace, Macro.camelize(Atom.to_string(metadata.type)))
        end

      new_metadata =
        new_metadata |> Map.put(:id, "#{new_metadata.namespace}.#{parse_text(metadata.text)}")

      if Graph.has_vertex?(new_g, new_metadata.id) do
        [existing] = Graph.vertex_labels(new_g, new_metadata.id)
        new_metadata = %{existing | vertex_ids: [vertex_id | existing.vertex_ids]}

        {:next, replace_labels(new_g, new_metadata.id, new_metadata)}
      else
        new_metadata = new_metadata |> Map.put(:vertex_ids, [vertex_id])

        {:next, Graph.add_vertex(new_g, new_metadata.id, new_metadata)}
      end
    end)
  end

  def replace_labels(g, vertex_id, metadata) do
    g
    |> Graph.delete_vertex(vertex_id)
    |> Graph.add_vertex(vertex_id, metadata)
  end

  defp id_to_title_map(g) do
    g
    |> Graph.vertices()
    |> Enum.reduce(%{}, fn title, map ->
      v = augment_vertex(g, title)

      Enum.reduce(v.vertex_ids, map, fn id, inner_map ->
        Map.put(inner_map, id, title)
      end)
    end)
  end

  defp add_title_edges(g, new_g, map) do
    g
    |> Graph.edges()
    |> Enum.reduce(new_g, fn %{v1: from, v2: to}, acc ->
      Graph.add_edge(acc, map[from], map[to])
    end)
  end

  def disjoint_groups(g) do
    Graph.components(g)
  end

  def lint(g) do
    g
    |> graph_map(fn vertex_id ->
      v = augment_vertex(g, vertex_id)

      if v.type in @node_types do
        check_node(g, v)
      end
    end)
    |> Enum.filter(fn
      nil -> false
      [] -> false
      _ -> true
    end)
  end

  defp check_node(g, %{type: type} = v) do
    node = @nodes[type]

    []
    |> check(node.expected_in, :in, g, v)
    |> check(node.expected_out, :out, g, v)
  end

  defp check(list, expected, :in, g, v) do
    log(list, v, apply(__MODULE__, expected, [:in, incoming(g, v.id), @ins[v.type]]))
  end

  defp check(list, expected, :out, g, v) do
    log(list, v, apply(__MODULE__, expected, [:out, outgoing(g, v.id), @outs[v.type]]))
  end

  defp log(list, _v, :ok), do: list
  defp log(list, v, {:error, reason}), do: ["#{v.id}'s #{reason}" | list]
  defp log(list, v, outputs), do: Enum.reduce(outputs, list, &log(&2, v, &1))

  def none(_dir, _, _t) do
    :ok
    # FIXME
  end

  def only_one(dir, [], _t), do: {:error, "should have one #{dir}"}

  def only_one(dir, [%{type: type}], types) when type in @node_types do
    if type in types,
      do: :ok,
      else: {:error, "#{dir} (#{type}) not one of [#{Enum.join(types, ", ")}]"}
  end

  def only_one(_dir, [_], _), do: :ok
  def only_one(dir, _, _t), do: {:error, "should only have one #{dir}"}

  def maybe_one_or_more(_dir, [], _t), do: :ok
  def maybe_one_or_more(dir, list, types), do: one_or_more(dir, list, types)

  def one_or_more(dir, [], _t), do: {:error, "should have one or more #{dir}s"}

  def one_or_more(dir, list, types) do
    Enum.map(
      list,
      fn v ->
        if v.type in @node_types do
          if v.type in types,
            do: :ok,
            else: {:error, "#{dir(dir)} #{v.id} not one of [#{Enum.join(types, ", ")}]"}
        else
          :ok
        end
      end
    )
  end

  def dir(:in), do: "in from"
  def dir(:out), do: "out to"

  def filter_by_type(g, type) do
    graph_filter(g, fn vertex_id ->
      case augment_vertex(g, vertex_id) do
        %{type: ^type} -> true
        _ -> false
      end
    end)
  end

  def outgoing(g, vertex_id) do
    g
    |> Graph.out_neighbors(vertex_id)
    |> augment_vertices(g)
  end

  def incoming(g, vertex_id) do
    g
    |> Graph.in_neighbors(vertex_id)
    |> augment_vertices(g)
  end

  defp start(line), do: get_in(line, ~w(startWidget id))
  defp finish(line), do: get_in(line, ~w(endWidget id))
  defp color(sticker), do: get_in(sticker, ~w(style backgroundColor))
  defp text(sticker), do: get_in(sticker, ~w(text))
  defp id(sticker), do: get_in(sticker, ~w(id))
  defp position(sticker), do: {get_in(sticker, ~w(x)), get_in(sticker, ~w(y))}

  defp graph_reduce(g, list, function) do
    Enum.reduce(list, g, function)
  end

  defp graph_filter(g, filter) do
    Graph.Reducers.Dfs.reduce(g, [], fn v, acc ->
      case filter.(v) do
        true -> {:next, [v | acc]}
        false -> {:skip, acc}
      end
    end)
  end

  def graph_map(g, mapper) do
    Graph.Reducers.Dfs.map(g, mapper)
  end

  defp augment_vertices(vertex_ids, g) do
    Enum.map(vertex_ids, &augment_vertex(g, &1))
  end

  defp augment_vertex(g, v) do
    case Graph.vertex_labels(g, v) do
      [z] ->
        Map.put(z, :id, v)

      a ->
        IO.inspect({a, v}, label: "augment error")
        raise("There should be exactly one label")
    end
  end

  defp parse_text(text) do
    parsed = Floki.parse_fragment!(text)

    {name_parts, _fields} =
      Enum.reduce(parsed, {[], []}, fn
        {"p", _attrs, [text]}, {name_parts, fields} ->
          case Regex.split(~r/^[^A-Za-z]/, text) do
            [_prefix, name] ->
              # Field
              name = String.trim(name)
              field = String.replace(name, ~r/\s/, "") |> Macro.underscore() |> String.to_atom()

              {name_parts, fields ++ [%{name: name, field: field}]}

            [name] ->
              # Title
              name = name |> String.trim() |> String.replace(~r/\s/, "")

              {name_parts ++ [name], fields}
          end

        {_tag_name, _attrs, _child_nodes}, acc ->
          acc
      end)

    name = Enum.join(name_parts, "")

    name
  end
end
