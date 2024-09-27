defmodule Jinx.DocServer do
  use GenServer

  @moduledoc """
  Documentation for `Jinx.DocServer`.
  """

  @doc """
  """

  def start_link(opts) do
    doc_id = Access.get(opts, :doc_id)
    client_pid = Access.get(opts, :client_pid)

    GenServer.start_link(__MODULE__,
      name: {:global, doc_id},
      doc_id: doc_id,
      client_pid: client_pid
    )
  end

  ## May need to defer to init_continue depending on the initialization time
  @impl GenServer
  def init(name: _name, doc_id: doc_id, client_pid: client_pid) do
    doc =
      Jinx.Doc.new(doc_id)
      |> Jinx.Doc.add_client(client_pid)

    {:ok, doc}
  end

  @impl GenServer
  def handle_cast({:apply_update, update}, %Jinx.Doc{} = state) do
    Jinx.Doc.apply_update(state, update)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:add_client, pid}, %Jinx.Doc{} = state) do
    {:noreply, Jinx.Doc.add_client(state, pid)}
  end

  @impl GenServer
  def handle_call({:get_doc_value, element_type, element_name}, _from, %Jinx.Doc{} = state) do
    case Jinx.Doc.get_doc_value(state, element_type, element_name) do
      {:ok, value} -> {:reply, {:ok, value}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl GenServer
  def handle_call(:get_connected_clients, _from, %Jinx.Doc{} = state) do
    {:reply, Jinx.Doc.connected_clients(state), state}
  end

  def open_doc(doc_id, client_pid) do
    case Jinx.DocServer.start_link(doc_id: doc_id, client_pid: client_pid) do
      {:ok, pid} -> {:ok, %Jinx.DocHandle{doc_id: doc_id, pid: pid}}
      _ -> {:error, "Could not open document"}
    end
  end

  def apply_update(doc_handle, update) do
    GenServer.cast(doc_handle.pid, {:apply_update, update})
  end

  def get_doc_value(doc_handle, element_type, element_name) do
    GenServer.call(doc_handle.pid, {:get_doc_value, element_type, element_name})
  end

  def add_client(doc_handle, pid) do
    GenServer.cast(doc_handle.pid, {:add_client, pid})
  end

  def get_connected_clients(doc_handle) do
    GenServer.call(doc_handle.pid, :get_connected_clients)
  end
end
