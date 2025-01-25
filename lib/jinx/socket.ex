defmodule Jinx.Socket do
  alias Ecto.Association.NotLoaded

  def handle_info({:jinx, records}, socket, opts) do
    watch = Keyword.get(opts, :watch, [])

    inserts =
      records
      |> Enum.filter(&(elem(&1, 0) == :insert))
      |> Enum.reduce([], fn {_op, record}, acc ->
        case Jinx.lookup_info(record) do
          nil -> acc
          lookup -> [{lookup, record} | acc]
        end
      end)

    updates =
      records
      |> Enum.reject(&(elem(&1, 0) == :insert))
      |> Enum.reduce([], fn {op, record}, acc ->
        case Jinx.lookup_info(record) do
          nil -> acc
          lookup -> [{lookup, {op, record}} | acc]
        end
      end)
      |> Map.new()

    socket =
      socket.assigns
      |> Map.take(watch)
      |> traverse_assigns(inserts, updates)
      |> Enum.reduce(socket, fn {k, v}, socket_acc ->
        # TODO: only call if assign has changed
        socket_acc.view.jinx_update(k, v, socket_acc)
      end)

    {:halt, socket}
  end

  def handle_info(_msg, socket, _opts) do
    {:cont, socket}
  end

  # TODO: changesets
  defp traverse_assigns(struct, inserts, updates) when is_struct(struct) do
    traverse_associations(struct, inserts, updates)
  end

  defp traverse_assigns(list, inserts, updates) when is_list(list) do
    list
    |> Enum.reduce([], fn item, acc ->
      case traverse_assigns(item, inserts, updates) do
        :delete -> acc
        item -> [item | acc]
      end
    end)
    |> Enum.reverse()
    |> maybe_insert(inserts)
  end

  defp traverse_assigns(map, inserts, updates) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, traverse_assigns(v, inserts, updates)} end)
  end

  defp traverse_assigns(value, _inserts, _updates) do
    value
  end

  defp process_record({:update, record}, original) do
    updated_fields =
      record
      |> Map.from_struct()
      |> Enum.filter(fn
        {_field, %NotLoaded{}} -> false
        _ -> true
      end)
      |> Map.new()

    # TODO: handle fkey ids changing, maybe set to NotLoaded
    Map.merge(original, updated_fields)
  end

  defp process_record({:delete, _record}, _original) do
    :delete
  end

  defp process_record(nil, original) do
    original
  end

  defp traverse_associations(%Ecto.Association.NotLoaded{} = struct, _inserts, _updates) do
    struct
  end

  defp traverse_associations(structs, inserts, updates) when is_list(structs) do
    Enum.map(structs, fn struct -> traverse_associations(struct, inserts, updates) end)
  end

  defp traverse_associations(%{__struct__: module} = struct, inserts, updates) do
    struct =
      case Jinx.lookup_info(struct) do
        nil -> struct
        lookup -> process_record(updates[lookup], struct)
      end

    if struct != :delete and Kernel.function_exported?(module, :__schema__, 1) do
      :associations
      |> module.__schema__()
      |> Enum.map(&module.__schema__(:association, &1))
      |> Enum.reduce(struct, fn assoc, acc ->
        record =
          struct
          |> Map.get(assoc.field)
          |> traverse_associations(inserts, updates)
          |> maybe_add_to_association(struct, assoc, inserts)

        %{acc | assoc.field => record}
      end)
    else
      struct
    end
  end

  defp traverse_associations(value, _inserts, _updates) do
    value
  end

  defp maybe_add_to_association(%Ecto.Association.NotLoaded{} = record, _parent, _assoc, _inserts), do: record

  defp maybe_add_to_association(list, parent, %Ecto.Association.Has{cardinality: :many} = assoc, inserts) do
    existing = Enum.map(list, &Jinx.lookup_info/1)

    relevant_inserts =
      inserts
      |> Enum.filter(fn {lookup, insert} ->
        insert.__struct__ == assoc.related and
          Map.get(insert, assoc.related_key) == Map.get(parent, assoc.owner_key) and
          lookup not in existing
      end)
      |> Enum.map(&elem(&1, 1))

    relevant_inserts ++ list
  end

  defp maybe_add_to_association(record, _parent, _assoc, _inserts), do: record

  # TODO: what if list is empty? how to populate first record
  defp maybe_insert([head | _rest] = list, inserts) do
    existing = Enum.map(list, &Jinx.lookup_info/1)

    relevant_inserts =
      inserts
      |> Enum.filter(fn {lookup, insert} ->
        insert.__struct__ == head.__struct__ and lookup not in existing
      end)
      |> Enum.map(&elem(&1, 1))

    relevant_inserts ++ list
  end

  defp maybe_insert(list, _inserts) do
    list
  end
end
