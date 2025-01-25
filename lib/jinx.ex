defmodule Jinx do
  @moduledoc false
  import Phoenix.LiveView

  defmacro __using__(opts) do
    quote do
      on_mount({Jinx, unquote(opts)})

      def jinx_update(key, value, socket), do: assign(socket, key, value)

      @before_compile {Jinx, :add_jinx_update_fallback}

      defoverridable jinx_update: 3
    end
  end

  defmacro add_jinx_update_fallback(_env) do
    quote do
      def jinx_update(key, value, socket), do: assign(socket, key, value)
    end
  end

  def on_mount(opts, _params, _session, socket) do
    if connected?(socket) do
      # TODO: customizable key to restrict for multitenancy
      Jinx.Replication.subscribe("jinx")

      {:cont,
       attach_hook(socket, :jinx, :handle_info, fn msg, socket ->
         Jinx.Socket.handle_info(msg, socket, opts)
       end)}
    else
      {:cont, socket}
    end
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
end
