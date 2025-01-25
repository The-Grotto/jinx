defmodule Jinx do
  @moduledoc false
  import Phoenix.Component
  import Phoenix.LiveView

  alias Ecto.Association.NotLoaded

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(DevHub.PubSub, "jinx")
    end

    {:cont, attach_hook(socket, :jinx, :handle_info, &do_handle_info/2)}
  end

  def opts(module) do
    Jinx.Sync.impl_for(struct(module)).opts()
  end

  def lookup_info(struct) do
    case Jinx.Sync.impl_for(struct) do
      nil -> nil
      impl -> impl.info(struct)
    end
  end

  defp do_handle_info({:jinx, records}, socket) do
    inserts =
      records
      |> Enum.filter(&(elem(&1, 0) == :insert))
      |> Enum.reduce([], fn {_op, record}, acc ->
        case lookup_info(record) do
          nil -> acc
          lookup -> [{lookup, record} | acc]
        end
      end)

    updates =
      records
      |> Enum.reject(&(elem(&1, 0) == :insert))
      |> Enum.reduce([], fn {op, record}, acc ->
        case lookup_info(record) do
          nil -> acc
          lookup -> [{lookup, {op, record}} | acc]
        end
      end)
      |> Map.new()

    assigns =
      socket.assigns
      |> Map.drop([:flash, :live_action])
      |> traverse_assigns(inserts, updates)

    {:halt, assign(socket, assigns)}
  end

  defp do_handle_info(_msg, socket) do
    {:cont, socket}
  end

  # TODO: preloaded associations
  # TODO: changesets
  defp traverse_assigns(struct, inserts, updates) when is_struct(struct) do
    struct =
      case lookup_info(struct) do
        nil -> struct
        lookup -> process_record(updates[lookup], struct)
      end

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
  end

  defp traverse_assigns(map, inserts, updates) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, traverse_assigns(v, inserts, updates)} end)
  end

  defp traverse_assigns(value, _inserts, _updates) do
    value
  end

  # TODO: how to handle inserts, for example in lists
  defp process_record({:update, record}, original) do
    updated_fields =
      record
      |> Map.from_struct()
      |> Enum.filter(fn
        {_field, %NotLoaded{}} ->
          false

        _ ->
          true
      end)
      |> Map.new()

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

  defp traverse_associations(%{__struct__: module} = struct, inserts, updates) do
    if Kernel.function_exported?(module, :__schema__, 1) do
      :associations
      |> module.__schema__()
      |> Enum.map(&module.__schema__(:association, &1))
      |> Enum.reduce(struct, fn assoc, acc ->
        record =
          struct
          |> Map.get(assoc.field)
          |> traverse_assigns(inserts, updates)
          |> maybe_insert(struct, assoc, inserts)

        %{acc | assoc.field => record}
      end)
    else
      struct
    end
  end

  defp traverse_associations(value, _inserts, _updates) do
    value
  end

  defp maybe_insert(%Ecto.Association.NotLoaded{} = record, _parent, _assoc, _inserts), do: record

  defp maybe_insert(list, parent, %Ecto.Association.Has{cardinality: :many} = assoc, inserts) do
    existing = Enum.map(list, &lookup_info/1)

    relevant_inserts =
      Enum.filter(
        inserts,
        fn {lookup, insert} ->
          insert.__struct__ == assoc.related and
            Map.get(insert, assoc.related_key) == Map.get(parent, assoc.owner_key) and
            lookup not in existing
        end
      )

    relevant_inserts ++ list
  end

  defp maybe_insert(record, _parent, _assoc, _inserts), do: record
end
