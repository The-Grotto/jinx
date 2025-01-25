defmodule Jinx.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Jinx.PubSub},
      {Jinx.Replication, [name: Jinx.Replication] ++ DevHub.Repo.config()},
      {Task, fn -> Jinx.Replication.wait_for_connection!(Jinx.Replication) end}
    ]

    opts = [strategy: :one_for_one, name: Jinx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
