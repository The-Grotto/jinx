defmodule Jinx.DocRegistry do
  @moduledoc false
  def start_link do
    Registry.start_link(
      name: __MODULE__,
      keys: :unique
    )
  end

  def via_tuple(doc_id) do
    {:via, Registry, {__MODULE__, doc_id}}
  end

  def child_spec(_opts) do
    Supervisor.child_spec(Registry, id: __MODULE__, start: {__MODULE__, :start_link, []})
  end
end
