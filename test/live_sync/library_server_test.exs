defmodule LibraryServerTest do
  use ExUnit.Case

  alias LiveSync.LibraryServer

  test "creates a document" do
    {:ok, _} = LibraryServer.start_link([])
    {:ok, doc_id} = LibraryServer.create_doc("123")

    client_doc = Yex.Doc.new()
    client_title = Yex.Doc.get_text(client_doc, "title")
    client_content = Yex.Doc.get_text(client_doc, "content")

    Yex.Text.insert(client_title, 0, "test title")
    Yex.Text.insert(client_content, 0, "test content")

    {:ok, update} = Yex.encode_state_as_update(client_doc)
    :ok = LibraryServer.apply_update(doc_id, update)

    assert doc_id == "123"
    assert LibraryServer.get_doc_value(doc_id, :text, "title") == {:ok, "test title"}
    assert LibraryServer.get_doc_value(doc_id, :text, "content") == {:ok, "test content"}
  end
end
