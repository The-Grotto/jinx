defmodule Jinx.Doc do
  @enforce_keys [:id, :ydoc]
  defstruct [:id, :ydoc, connected_clients: MapSet.new()]

  def new(doc_id) do
    %Jinx.Doc{id: doc_id, ydoc: Yex.Doc.new()}
  end

  def add_client(%Jinx.Doc{} = doc, pid) do
    %Jinx.Doc{doc | connected_clients: MapSet.put(doc.connected_clients, pid)}
  end

  def remove_client(%Jinx.Doc{} = doc, pid) do
    %Jinx.Doc{doc | connected_clients: MapSet.delete(doc.connected_clients, pid)}
  end

  def connected_clients(%Jinx.Doc{} = doc) do
    MapSet.to_list(doc.connected_clients)
  end

  def has_connected_clients?(%Jinx.Doc{} = doc) do
    MapSet.size(doc.connected_clients) > 0
  end

  def apply_update(%Jinx.Doc{ydoc: ydoc} = doc, update) do
    Yex.apply_update(ydoc, update)
    doc
  end

  def get_doc_value(%Jinx.Doc{} = doc, element_type, element_name) do
    case element_type do
      :array -> {:ok, get_array_value(doc, element_name)}
      :text -> {:ok, get_text_value(doc, element_name)}
      :xml_fragment -> {:ok, get_xml_fragment_value(doc, element_name)}
      :map -> {:ok, get_map_value(doc, element_name)}
      _type -> {:error, "Unknown element type"}
    end
  end

  def get_array_value(%Jinx.Doc{ydoc: ydoc}, name) do
    ydoc
    |> Yex.Doc.get_array(name)
    |> Yex.Array.to_list()
  end

  def get_text_value(%Jinx.Doc{ydoc: ydoc}, name) do
    ydoc
    |> Yex.Doc.get_text(name)
    |> Yex.Text.to_string()
  end

  def get_xml_fragment_value(%Jinx.Doc{ydoc: ydoc}, name) do
    ydoc
    |> Yex.Doc.get_xml_fragment(name)
    |> Yex.XmlFragment.to_string()
  end

  def get_map_value(%Jinx.Doc{ydoc: ydoc}, name) do
    ydoc
    |> Yex.Doc.get_map(name)
    |> Yex.Map.to_map()
  end
end
