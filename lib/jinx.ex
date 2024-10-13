defmodule Jinx do
  @moduledoc """
  Documentation for `Jinx`.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def child_spec(opts) do
    %{
      id: Jinx,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(_opts) do
    children = [
      {Phoenix.PubSub, name: Jinx.PubSub},
      Jinx.DocRegistry,
      Jinx.DocCache
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
