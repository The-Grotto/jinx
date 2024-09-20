defmodule LiveSync.Alexandria do
  use GenServer

  def init(_) do
    {:ok, %{}}
  end

  def start(opts) do
    server_name = Access.get(opts, :name, __MODULE__)
    GenServer.start(__MODULE__, %{}, name: server_name)
  end

  def handle_call({:create_doc, doc_id, root_elements}, _from, state) do
    doc = Yex.Doc.new()

    Enum.each(root_elements, fn {element_name, element_type} ->
      case add_element(doc, element_type, element_name) do
        {:ok, _} -> :ok
        {:error, reason} -> IO.puts("Error: #{reason}")
      end
    end)

    {:reply, {:ok, doc_id}, Map.put(state, doc_id, doc)}
  end

  def handle_call({:open_document, doc_id}, _from, state) do
    case Map.get(state, doc_id) do
      nil -> {:reply, {:error, "Document not found"}, state}
      doc -> {:reply, {:ok, doc}, state}
    end
  end

  def handle_call({:get_doc_value, doc_id, element_type, name}, _from, state) do
    doc = Map.get(state, doc_id, nil)

    result =
      case element_type do
        :array ->
          doc
          |> Yex.Doc.get_array(name)
          |> Yex.Array.to_list()

        :text ->
          doc
          |> Yex.Doc.get_text(name)
          |> Yex.Text.to_string()

        :xml_fragment ->
          doc
          |> Yex.Doc.get_xml_fragment(name)
          |> Yex.XmlFragment.to_string()
      end

    {:reply, result, state}
  end

  def handle_cast({:apply_update, doc_id, update}, state) do
    Map.get(state, doc_id) |> Yex.apply_update(update)

    {:noreply, state}
  end

  def create_doc(server_name \\ __MODULE__, doc_id, root_elements) do
    GenServer.call(server_name, {:create_doc, doc_id, root_elements})
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

  defp add_element(doc, :array, name) do
    {:ok, Yex.Doc.get_array(doc, name)}
  end

  defp add_element(doc, :xml_fragment, name) do
    {:ok, Yex.Doc.get_xml_fragment(doc, name)}
  end

  defp add_element(doc, :text, name) do
    {:ok, Yex.Doc.get_text(doc, name)}
  end

  defp add_element(doc, :map, name) do
    {:ok, Yex.Doc.get_map(doc, name)}
  end

  defp add_element(_doc, element_type, _) do
    {:error, "Unknown element type: #{element_type}"}
  end
end
