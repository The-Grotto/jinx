defmodule Jinx.DocRegistry do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  ## Once the document storage is implemented, can implement a specific function for creating a new document.
  @impl GenServer
  def handle_call({:open_doc, doc_id, alt_client_pid}, client_pid, state) do
    # Use the alternate client pid if provided, otherwise use the defult client pid of the caller
    client_pid = alt_client_pid || client_pid

    case Map.get(state, doc_id) do
      nil ->
        start_new_doc(doc_id, client_pid, state)

      doc_handle ->
        Jinx.DocServer.add_client(doc_handle, client_pid)
        {:reply, {:ok, doc_handle}, state}
    end
  end

  def open_doc(doc_id, client_pid \\ nil) do
    GenServer.call(__MODULE__, {:open_doc, doc_id, client_pid})
  end

  defp start_new_doc(doc_id, client_pid, state) do
    case Jinx.DocServer.open_doc(doc_id, client_pid) do
      {:ok, doc_handle} ->
        {:reply, {:ok, doc_handle}, Map.put(state, doc_id, doc_handle)}

      {:error, message} ->
        {:reply, {:error, message}, state}
    end
  end
end
