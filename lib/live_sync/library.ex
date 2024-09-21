defmodule LiveSync.Library do
  defstruct documents: %{}

  def create_doc(%__MODULE__{} = library, doc_id) do
    library = %{library | documents: Map.put(library.documents, doc_id, Yex.Doc.new())}

    {:ok, doc_id, library}
  end

  def get_doc(%__MODULE__{} = library, doc_id) do
    Map.get(library.documents, doc_id)
  end

  def apply_update(%__MODULE__{} = library, doc_id, update) do
    get_doc(library, doc_id) |> Yex.apply_update(update)
  end

  def get_doc_value(%__MODULE__{} = library, doc_id, element_type, name) do
    case element_type do
      :array -> {:ok, get_array(library, doc_id, name)}
      :text -> {:ok, get_text(library, doc_id, name)}
      :xml_fragment -> {:ok, get_xml_fragment(library, doc_id, name)}
      :map -> {:ok, get_map(library, doc_id, name)}
      _ -> {:error, "Unknown element type"}
    end
  end

  def get_array(library, doc_id, name) do
    get_doc(library, doc_id) |> Yex.Doc.get_array(name) |> Yex.Array.to_list()
  end

  def get_text(library, doc_id, name) do
    get_doc(library, doc_id) |> Yex.Doc.get_text(name) |> Yex.Text.to_string()
  end

  def get_xml_fragment(library, doc_id, name) do
    get_doc(library, doc_id) |> Yex.Doc.get_xml_fragment(name) |> Yex.XmlFragment.to_string()
  end

  def get_map(library, doc_id, name) do
    get_doc(library, doc_id) |> Yex.Doc.get_map(name) |> Yex.Map.to_map()
  end
end
