defmodule Jinx.DocServer do
  @moduledoc """
  Documentation for `Jinx.DocServer`.
  """

  @doc """
  """

  def start_link(opts) do
    doc_id = Access.get(opts, :doc_id)
    GenServer.start_link(__MODULE__, name: {:global, doc_id}, doc_id: doc_id)
  end

  ## May need to defer to init_continue depending on the initialization time
  def init(doc_id) do
    {:ok, global_open_doc(doc_id)}
  end

  def handle_cast({:apply_update, update}, %Jinx.Doc{} = state) do
    Jinx.Doc.apply_update(state, update)
    {:noreply, state}
  end

  def handle_call({:get_doc_value, element_type, element_name}, _from, %Jinx.Doc{} = state) do
    case Jinx.Doc.get_doc_value(state, element_type, element_name) do
      {:ok, value} -> {:reply, {:ok, value}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def open_doc(doc_id) do
    Jinx.DocServer.start_link(doc_id: doc_id)
  end

  def apply_update(pid, update) do
    # GenServer.cast({:global, doc_id}, {:apply_update, update})
    GenServer.cast(pid, {:apply_update, update})
  end

  def get_doc_value(pid, element_type, element_name) do
    # GenServer.call({:global, doc_id}, {:get_doc_value, element_type, element_name})
    GenServer.call(pid, {:get_doc_value, element_type, element_name})
  end

  defp global_open_doc(doc_id) do
    Jinx.Doc.new(doc_id)
  end
end
