defmodule LiveSync.Library do
  use GenServer

  alias Yex.Doc

  alias UXID

  def init(_) do
    {:ok, %{}}
  end

  def start() do
    GenServer.start(__MODULE__, %{}, name: __MODULE__)
  end

  def handle_call({:create_doc, root_elements}, _from, state) do
    doc = Doc.new()

    Enum.each(root_elements, fn {element_name, element_type} ->
      case add_element(doc, element_type, element_name) do
        {:ok, _} -> :ok
        {:error, reason} -> IO.puts("Error: #{reason}")
      end
    end)

    {:ok, doc_id} = UXID.generate(prefix: "doc")

    {:reply, {:ok, doc_id, doc}, Map.put(state, doc_id, doc)}
  end

  def handle_call({:get_document, doc_id}, _from, state) do
    case Map.get(state, doc_id) do
      nil -> {:reply, {:error, "Document not found"}, state}
      doc -> {:reply, {:ok, doc}, state}
    end
  end

  def create_doc(root_elements) do
    GenServer.call(__MODULE__, {:create_doc, root_elements})
  end

  def get_document(doc_id) do
    GenServer.call(__MODULE__, {:get_document, doc_id})
  end

  defp add_element(doc, :array, name) do
    {:ok, Doc.get_array(doc, name)}
  end

  defp add_element(doc, :xml_fragment, name) do
    {:ok, Doc.get_xml_fragment(doc, name)}
  end

  defp add_element(doc, :text, name) do
    {:ok, Doc.get_text(doc, name)}
  end

  defp add_element(doc, :map, name) do
    {:ok, Doc.get_map(doc, name)}
  end

  defp add_element(_doc, element_type, _) do
    {:error, "Unknown element type: #{element_type}"}
  end
end
