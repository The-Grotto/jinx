defmodule Jinx.DocServerTest do
  use ExUnit.Case

  test "creates a doc" do
    {:ok, pid} = Jinx.DocServer.start_link("111")

    client_doc = Yex.Doc.new()
    client_text = Yex.Doc.get_text(client_doc, "test_text")
    Yex.Text.insert(client_text, 0, "test text input data")

    {:ok, update} = Yex.encode_state_as_update(client_doc)

    Jinx.DocServer.apply_update(pid, update)

    assert Jinx.DocServer.get_doc_value(pid, :text, "test_text") ==
             {:ok, "test text input data"}
  end
end
