defmodule DEMOALCHEMY do
  use Application

  @impl true
  def start(_type, _args) do
    DEMOALCHEMY.Supervisor.start_link(name: DEMOALCHEMY.Supervisor)
  end
end
