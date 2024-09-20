defmodule AlexandriaTest do
  use ExUnit.Case

  alias Yex.{Doc, Text}
  alias LiveSync.Alexandria

  defp setup_alexandria(name) do
    {:ok, _alexandria} = Alexandria.start(name: name)
  end

  test "creates a document" do
    setup_alexandria(:create_doc)

    {:ok, doc_id} =
      Alexandria.create_doc(:create_doc, "123", %{
        "title" => :text,
        "content" => :text
      })

    client_doc = Doc.new()
    title = Doc.get_text(client_doc, "title")
    content = Doc.get_text(client_doc, "content")

    Text.insert(title, 0, "test title")
    Text.insert(content, 0, "test content")

    {:ok, update} = Yex.encode_state_as_update(client_doc)
    :ok = Alexandria.apply_update(:create_doc, doc_id, update)

    assert doc_id == "123"
    assert Alexandria.get_doc_value(:create_doc, doc_id, :text, "title") == "test title"
    assert Alexandria.get_doc_value(:create_doc, doc_id, :text, "content") == "test content"
  end
end
