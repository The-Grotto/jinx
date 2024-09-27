defmodule Jinx.DocRegistryTest do
  use ExUnit.Case

  setup %{} do
    Jinx.DocRegistry.start_link([])
    %{}
  end

  test "create a new doc" do
    {:ok, doc_handle} = Jinx.DocRegistry.open_doc("123", self())

    client_doc = Yex.Doc.new()
    client_title = Yex.Doc.get_text(client_doc, "title")
    client_content = Yex.Doc.get_text(client_doc, "content")

    Yex.Text.insert(client_title, 0, "test title")
    Yex.Text.insert(client_content, 0, "test content")

    {:ok, update} = Yex.encode_state_as_update(client_doc)
    :ok = Jinx.DocServer.apply_update(doc_handle, update)

    assert Jinx.DocServer.get_doc_value(doc_handle, :text, "title") == {:ok, "test title"}
    assert Jinx.DocServer.get_doc_value(doc_handle, :text, "content") == {:ok, "test content"}
  end

  test "opens an existing doc" do
    {:ok, doc_handle_one} = Jinx.DocRegistry.open_doc("123", self())
    {:ok, doc_handle_two} = Jinx.DocRegistry.open_doc("123", :c.pid(0, 250, 0))
    {:ok, doc_handle_three} = Jinx.DocRegistry.open_doc("456", self())

    assert doc_handle_one.doc_id == doc_handle_two.doc_id
    assert doc_handle_one.pid == doc_handle_two.pid
    assert doc_handle_one.doc_id != doc_handle_three.doc_id
    assert doc_handle_one.pid != doc_handle_three.pid
  end

  test "maintains connected clients" do
    {:ok, doc_handle_one} = Jinx.DocRegistry.open_doc("connected_clients", :first_pid)
    {:ok, _doc_handle_two} = Jinx.DocRegistry.open_doc("connected_clients", :pretend_pid)
    {:ok, _doc_handle_three} = Jinx.DocRegistry.open_doc("connected_clients", :another_pid)

    connected_clients = Jinx.DocServer.get_connected_clients(doc_handle_one)

    assert connected_clients == [:first_pid, :pretend_pid, :another_pid]
  end

  # test "closes an open doc" do
  #   {:ok, doc_handle_one} = Jinx.DocRegistry.open_doc("123", :c.pid(0, 252, 0))
  #   {:ok, doc_handle_two} = Jinx.DocRegistry.open_doc("123", :c.pid(0, 253, 0))
  #
  #   connected_clients = Jinx.DocServer.get_connected_clients(doc_handle_one)
  #
  #   assert doc_handle_one.pid == doc_handle_two.pid
  #   assert connected_clients == [:c.pid(0, 252, 0), :c.pid(0, 253, 0)]
  #
  #   ## This should remove the connected client but not shutdown the server
  #   Jinx.DocRegistry.close_doc(doc_handle_one, :c.pid(0, 252, 0))
  #   connected_clients = Jinx.DocServer.get_connected_clients(doc_handle_two)
  #
  #   assert connected_clients == [:c.pid(0, 253, 0)]
  #
  #   ## This should remove the last connected client and shutdown the server
  #   Jinx.DocRegistry.close_doc(doc_handle_two, :c.pid(0, 253, 0))
  #
  #   ## Assert some kind of error or failure here - there should be no doc server available for this handle
  #   connected_clients = Jinx.DocServer.get_connected_clients(doc_handle_two)
  #
  #   ##
  #   {:ok, doc_handle_three} = Jinx.DocRegistry.open_doc("123", :c.pid(0, 254, 0))
  #
  #   assert doc_handle_one.pid != doc_handle_three.pid
  # end
end
