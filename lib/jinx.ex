defmodule Jinx do
  @moduledoc false
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(DevHub.PubSub, "jinx")
    end

    {:cont, attach_hook(socket, :jinx, :handle_info, &do_handle_info/2)}
  end

  def opts(module) do
    Jinx.Sync.impl_for(struct(module)).opts()
  end

  def lookup(struct) do
    case Jinx.Sync.impl_for(struct) do
      nil -> nil
      impl -> impl.info(struct)
    end
  end

  defp do_handle_info({:jinx, records}, socket) do
    records =
      records
      |> Enum.reduce([], fn record, acc ->
        case lookup(record) do
          nil -> acc
          lookup -> [{lookup, record} | acc]
        end
      end)
      |> Map.new()

    assigns =
      socket.assigns
      |> traverse_assigns(records)
      |> Map.drop([:flash, :live_action])

    {:halt, assign(socket, assigns)}
  end

  defp do_handle_info(_msg, socket) do
    {:cont, socket}
  end

  # TODO: preloaded associations
  defp traverse_assigns(struct, records) when is_struct(struct) do
    case lookup(struct) do
      nil -> struct
      lookup -> records[lookup]
    end
  end

  defp traverse_assigns(list, records) when is_list(list) do
    Enum.map(list, &traverse_assigns(&1, records))
  end

  defp traverse_assigns(map, records) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, traverse_assigns(v, records)} end)
  end

  defp traverse_assigns(value, _records) do
    value
  end
end
