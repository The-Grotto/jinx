defmodule Jinx.DocServer do
  @moduledoc """
  Documentation for `Jinx.DocServer`.
  """

  use GenServer, restart: :transient

  @doc """
  """

  def start_link(doc_id) do
    GenServer.start_link(__MODULE__, doc_id, name: via_tuple(doc_id))
  end

  def via_tuple(doc_id) do
    Jinx.DocRegistry.via_tuple({__MODULE__, doc_id})
  end

  ## May need to defer to init_continue depending on the initialization time
  @impl GenServer
  def init(doc_id) do
    doc = Jinx.Doc.new(doc_id)

    {:ok, doc}
  end

  @impl GenServer
  def handle_cast({:apply_update, update}, %Jinx.Doc{} = state) do
    Jinx.Doc.apply_update(state, update)

    Phoenix.PubSub.broadcast_from(
      Jinx.PubSub,
      self(),
      "jinx.update:#{state.id}",
      {state.id, update}
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:add_client, client_pid}, %Jinx.Doc{} = state) do
    {:noreply, Jinx.Doc.add_client(state, client_pid)}
  end

  @impl GenServer
  def handle_call({:remove_client, client_pid}, _from, %Jinx.Doc{} = state) do
    state = Jinx.Doc.remove_client(state, client_pid)

    if Jinx.Doc.has_connected_clients?(state) do
      {:reply, :connected_clients, state}
    else
      {:reply, :no_clients, state}
    end
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

  def subscribe(doc_id) do
    Phoenix.PubSub.subscribe(Jinx.PubSub, "jinx.update:#{doc_id}")
  end

  def apply_update(doc_pid, update) do
    GenServer.cast(doc_pid, {:apply_update, update})
  end

  def get_doc_value(doc_pid, element_type, element_name) do
    GenServer.call(doc_pid, {:get_doc_value, element_type, element_name})
  end

  def add_client(doc_pid, client_pid) do
    GenServer.cast(doc_pid, {:add_client, client_pid})
    doc_pid
  end

  def remove_client(doc_pid, client_pid) do
    GenServer.call(doc_pid, {:remove_client, client_pid})
  end

  def get_connected_clients(doc_pid) do
    GenServer.call(doc_pid, :get_connected_clients)
  end
end
