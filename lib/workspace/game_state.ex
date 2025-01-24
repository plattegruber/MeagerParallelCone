defmodule Workspace.GameState do
  use GenServer
  
  @initial_state %{
    phase: :prep,
    players: ["Gandalf", "Aragorn", "Legolas"],
    claimed_players: %{},  # Will be %{"Gandalf" => "device_123"}
    player_initiatives: %{},
    monsters: [],
    combat_order: [],
    current_turn: 0
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def set_state(state) do
    # Filter out only the keys we care about
    filtered_state = Map.take(state, Map.keys(@initial_state))
    GenServer.cast(__MODULE__, {:set_state, filtered_state})
  end

  @impl true 
  def init(_) do
    {:ok, @initial_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:set_state, new_state}, _state) do
    Phoenix.PubSub.broadcast(Workspace.PubSub, "game_state", {:state_updated, new_state})
    {:noreply, new_state}
  end
end