defmodule ALCHEMY do
  use Application

  @impl true
  def start(_type, _args) do
    ALCHEMY.Supervisor.start_link(name: ALCHEMY.Supervisor)
  end
end
