defmodule Jinx.DocRegistryTest do
  use ExUnit.Case, async: true

  test "create a new doc" do
    doc_pid = Jinx.DocCache.open_doc("123")

    client_doc = Yex.Doc.new()
    client_title = Yex.Doc.get_text(client_doc, "title")
    client_content = Yex.Doc.get_text(client_doc, "content")

    Yex.Text.insert(client_title, 0, "test title")
    Yex.Text.insert(client_content, 0, "test content")

    {:ok, update} = Yex.encode_state_as_update(client_doc)
    :ok = Jinx.DocServer.apply_update(doc_pid, update)

    assert Jinx.DocServer.get_doc_value(doc_pid, :text, "title") == {:ok, "test title"}
    assert Jinx.DocServer.get_doc_value(doc_pid, :text, "content") == {:ok, "test content"}
  end

  test "opens an existing doc" do
    doc_pid_one = Jinx.DocCache.open_doc("123")
    doc_pid_two = Jinx.DocCache.open_doc("123", :c.pid(0, 250, 0))
    doc_pid_three = Jinx.DocCache.open_doc("456", self())

    assert doc_pid_one == doc_pid_two
    assert doc_pid_one != doc_pid_three
  end

  test "maintains connected clients" do
    doc_pid_one = Jinx.DocCache.open_doc("connected_clients", :first_pid)
    _doc_pid_two = Jinx.DocCache.open_doc("connected_clients", :pretend_pid)
    _doc_pid_three = Jinx.DocCache.open_doc("connected_clients", :another_pid)

    connected_clients = Jinx.DocServer.get_connected_clients(doc_pid_one)

    assert connected_clients == [:first_pid, :pretend_pid, :another_pid]
  end

  test "closes an open doc" do
    doc_pid_one = Jinx.DocCache.open_doc("444", :c.pid(0, 252, 0))
    doc_pid_two = Jinx.DocCache.open_doc("444", :c.pid(0, 253, 0))
    doc_pid_three = Jinx.DocCache.open_doc("444", :c.pid(0, 254, 0))

    connected_clients = Jinx.DocServer.get_connected_clients(doc_pid_one)

    assert doc_pid_one == doc_pid_two
    assert doc_pid_two == doc_pid_three
    assert connected_clients == [:c.pid(0, 252, 0), :c.pid(0, 253, 0), :c.pid(0, 254, 0)]

    ## This should remove the connected client but not shutdown the server
    Jinx.DocCache.close_doc(doc_pid_one, :c.pid(0, 252, 0))
    connected_clients = Jinx.DocServer.get_connected_clients(doc_pid_two)

    assert connected_clients == [:c.pid(0, 253, 0), :c.pid(0, 254, 0)]

    ## This should remove the last connected client and shutdown the server
    Jinx.DocCache.close_doc(doc_pid_two, :c.pid(0, 253, 0))
    connected_clients = Jinx.DocServer.get_connected_clients(doc_pid_three)

    assert connected_clients == [:c.pid(0, 254, 0)]

    Jinx.DocCache.close_doc(doc_pid_three, :c.pid(0, 254, 0))
    catch_exit(Jinx.DocServer.get_connected_clients(doc_pid_three))

    doc_pid_four = Jinx.DocCache.open_doc("123", :c.pid(0, 254, 0))

    assert doc_pid_one != doc_pid_four
  end

  test "broadcasts doc updates on pubsub" do
    doc_id = "broadcast"

    doc_pid = Jinx.DocCache.open_doc(doc_id, :client_one)
    Jinx.DocCache.open_doc(doc_id, :client_two)

    Jinx.DocServer.subscribe(doc_id)

    client_doc = Yex.Doc.new()
    client_content = Yex.Doc.get_text(client_doc, "content")

    Yex.Text.insert(client_content, 0, "test broadcast content")

    {:ok, update} = Yex.encode_state_as_update(client_doc)
    :ok = Jinx.DocServer.apply_update(doc_pid, update)

    assert Jinx.DocServer.get_doc_value(doc_pid, :text, "content") ==
             {:ok, "test broadcast content"}

    assert_receive {^doc_id, ^update}

    client_text =
      doc_id
      |> Jinx.Doc.new()
      |> Jinx.Doc.apply_update(update)
      |> Jinx.Doc.get_doc_value(:text, "content")

    assert client_text == {:ok, "test broadcast content"}
  end
end
