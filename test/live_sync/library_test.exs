defmodule LibraryTest do
  use ExUnit.Case

  alias Yex.XmlElementPrelim
  alias LiveSync.Library
  alias Yex.{Doc, Text, Array, Map, XmlFragment, XmlTextPrelim}

  setup do
    {:ok, doc_id, library} = Library.create_doc(%Library{}, "123")
    client_doc = Doc.new()

    %{library: library, doc_id: doc_id, client_doc: client_doc}
  end

  describe "creates a doc" do
    test "with text", %{library: library, doc_id: doc_id, client_doc: client_doc} do
      client_title = Doc.get_text(client_doc, "title")
      client_content = Doc.get_text(client_doc, "content")

      Text.insert(client_title, 0, "test title")
      Text.insert(client_content, 0, "test content")

      {:ok, update} = Yex.encode_state_as_update(client_doc)
      :ok = Library.apply_update(library, doc_id, update)

      assert Library.get_doc_value(library, doc_id, :text, "title") == {:ok, "test title"}
      assert Library.get_doc_value(library, doc_id, :text, "content") == {:ok, "test content"}
    end

    test "with array", %{library: library, doc_id: doc_id, client_doc: client_doc} do
      client_items = Doc.get_array(client_doc, "items")

      Array.insert(client_items, 0, "item 1")
      Array.insert(client_items, 1, "item 2")

      {:ok, update} = Yex.encode_state_as_update(client_doc)
      :ok = Library.apply_update(library, doc_id, update)

      assert Library.get_doc_value(library, doc_id, :array, "items") ==
               {:ok, ["item 1", "item 2"]}
    end

    test "with xml", %{library: library, doc_id: doc_id, client_doc: client_doc} do
      client_title = Doc.get_xml_fragment(client_doc, "title")

      XmlFragment.push(client_title, XmlTextPrelim.from("xml title"))
      XmlFragment.unshift(client_title, XmlElementPrelim.empty("div"))

      {:ok, update} = Yex.encode_state_as_update(client_doc)
      :ok = Library.apply_update(library, doc_id, update)

      assert Library.get_doc_value(library, doc_id, :xml_fragment, "title") ==
               {:ok, "<div></div>xml title"}
    end

    test "with map", %{library: library, doc_id: doc_id, client_doc: client_doc} do
      client_map = Doc.get_map(client_doc, "map")

      Map.set(client_map, "key1", "value1")
      Map.set(client_map, "key2", "value2")

      {:ok, update} = Yex.encode_state_as_update(client_doc)
      :ok = Library.apply_update(library, doc_id, update)

      assert Library.get_doc_value(library, doc_id, :map, "map") ==
               {:ok, %{"key1" => "value1", "key2" => "value2"}}
    end
  end
end
