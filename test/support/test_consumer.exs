defmodule TestConsumer do
  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    test_pid = Keyword.fetch!(opts, :test_pid)

    {:consumer, %{test_pid: test_pid},
     subscribe_to: [{Keyword.fetch!(opts, :producer), max_demand: 10}]}
  end

  def handle_events(events, _from, state) do
    send(state.test_pid, {:events, events})
    {:noreply, [], state}
  end
end
