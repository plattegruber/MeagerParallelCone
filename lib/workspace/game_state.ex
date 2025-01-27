defmodule Workspace.GameState do
  use GenServer
  
  @initial_state %{
    phase: :prep,
    players: ["Gandalf"],
    claimed_players: %{},
    player_initiatives: %{},
    monsters: [],
    combat_order: [],
    current_turn: 0,
    combat_history: []  # Add this line
  }

  # Add new function to handle history
  def add_history_entry(entry) do
    GenServer.cast(__MODULE__, {:add_history_entry, entry})
  end

  def delete_history_entry(entry_id) do
    GenServer.cast(__MODULE__, {:delete_history_entry, entry_id})
  end

  @impl true
  def handle_cast({:add_history_entry, entry}, state) do
    entry_with_id = Map.put(entry, :id, generate_id())
    new_state = Map.update!(state, :combat_history, &[entry_with_id | &1])
    Phoenix.PubSub.broadcast(Workspace.PubSub, "game_state", {:state_updated, new_state})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:delete_history_entry, entry_id}, state) do
    # Find the entry to get the original change
    entry = Enum.find(state.combat_history, &(&1.id == entry_id))
    
    # Remove the entry from history
    new_history = Enum.reject(state.combat_history, &(&1.id == entry_id))
    
    # Undo the HP change if entry exists
    new_combat_order = if entry do
      undo_hp_change(state.combat_order, entry)
    else
      state.combat_order
    end

    new_state = %{state | combat_history: new_history, combat_order: new_combat_order}
    Phoenix.PubSub.broadcast(Workspace.PubSub, "game_state", {:state_updated, new_state})
    {:noreply, new_state}
  end

  defp generate_id, do: :crypto.strong_rand_bytes(16) |> Base.encode16()

  defp undo_hp_change(combat_order, entry) do
    Enum.map(combat_order, fn creature ->
      if creature.name == entry.creature_name do
        # Reverse the HP change
        reversed_amount = if entry.type == :damage, do: entry.amount, else: -entry.amount
        Map.update!(creature, :hp, &(max(0, min(&1 + reversed_amount, creature.max_hp))))
      else
        creature
      end
    end)
  end

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