defmodule Jinx.LibraryServer do
  use GenServer

  alias Jinx.Library

  def init(_) do
    {:ok, %Library{}}
  end

  def start_link(opts) do
    server_name = Access.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %Library{}, name: server_name)
  end

  def handle_call({:create_doc, doc_id}, _from, state) do
    {:ok, doc_id, state} = Library.create_doc(state, doc_id)

    {:reply, {:ok, doc_id}, state}
  end

  def handle_call({:open_document, doc_id}, _from, state) do
    case Library.get_doc(state, doc_id) do
      nil -> {:reply, {:error, "Document not found"}, state}
      doc -> {:reply, {:ok, doc}, state}
    end
  end

  def handle_call({:get_doc_value, doc_id, element_type, element_name}, _from, state) do
    {:reply, Library.get_doc_value(state, doc_id, element_type, element_name), state}
  end

  def handle_cast({:apply_update, doc_id, update}, state) do
    Library.apply_update(state, doc_id, update)

    {:noreply, state}
  end

  def create_doc(server_name \\ __MODULE__, doc_id) do
    GenServer.call(server_name, {:create_doc, doc_id})
  end

  def open_document(server_name \\ __MODULE__, doc_id) do
    GenServer.call(server_name, {:open_document, doc_id})
  end

  def apply_update(server_name \\ __MODULE__, doc_id, update) do
    GenServer.cast(server_name, {:apply_update, doc_id, update})
  end

  def get_doc_value(server_name \\ __MODULE__, doc_id, element_type, name) do
    GenServer.call(server_name, {:get_doc_value, doc_id, element_type, name})
  end
end
