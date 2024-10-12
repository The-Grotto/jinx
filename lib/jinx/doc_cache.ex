defmodule Jinx.DocCache do
  def start_link() do
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def open_doc(doc_id, client_pid \\ nil) do
    client_pid = client_pid || self()

    pid =
      case start_child(doc_id) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    Jinx.DocServer.add_client(pid, client_pid)
  end

  def close_doc(doc_pid, client_pid \\ nil) do
    client_pid = client_pid || self()

    case Jinx.DocServer.remove_client(doc_pid, client_pid) do
      :connected_clients ->
        :ok

      :no_clients ->
        DynamicSupervisor.terminate_child(__MODULE__, doc_pid)
        :ok
    end
  end

  defp start_child(doc_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Jinx.DocServer, doc_id}
    )
  end
end
