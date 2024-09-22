defmodule Jinx.DocTest do
  use ExUnit.Case

  test "creates a doc" do
    %Jinx.Doc{} = doc = Jinx.Doc.new("111")

    client_doc = Yex.Doc.new()
    client_text = Yex.Doc.get_text(client_doc, "test_text")

    Yex.Text.insert(client_text, 0, "test text input data")

    {:ok, update} = Yex.encode_state_as_update(client_doc)

    Jinx.Doc.apply_update(doc, update)

    assert Jinx.Doc.get_doc_value(doc, :text, "test_text") ==
             {:ok, "test text input data"}
  end
end
