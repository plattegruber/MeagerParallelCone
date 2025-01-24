import WorkspaceWeb.GameComponents

defmodule WorkspaceWeb.DMLive do
  use WorkspaceWeb, :live_view

  @monster_bank [
    %{name: "Goblin", hp: 7, initiative_bonus: 2},
    %{name: "Orc", hp: 15, initiative_bonus: 2},
    %{name: "Troll", hp: 84, initiative_bonus: 0},
    %{name: "Wolf", hp: 11, initiative_bonus: 2},
    %{name: "Giant Spider", hp: 26, initiative_bonus: 3}
  ]

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Workspace.PubSub, "game_state")
      state = Workspace.GameState.get_state()
      {:ok, assign(socket, Map.merge(state, %{monster_bank: @monster_bank, is_dm: true}))}
    else
      initial_state = %{
        phase: :prep,
        is_dm: true,  # Added this line
        players: ["Gandalf", "Aragorn", "Legolas"],
        claimed_players: %{},
        player_initiatives: %{},
        monsters: [],
        combat_order: [],
        current_turn: 0,
        monster_bank: @monster_bank
      }
      {:ok, assign(socket, initial_state)}
    end
  end

  def render(assigns) do
    case assigns.phase do
      :prep -> render_prep(assigns)
      :rolling -> render_rolling(assigns)
      :combat -> render_combat(assigns)
    end
  end

  # Just moving our existing setup view to prep for now
  def render_prep(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-6xl">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-4xl font-bold text-gray-900">DM Setup</h1>
          <button 
            phx-click="start_rolling" 
            type="button" 
            class="bg-green-600 hover:bg-green-700 text-white font-medium py-3 px-8 rounded-lg text-lg transition-colors duration-200 shadow-sm"
          >
            Start Rolling Phase
          </button>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Left Column -->
          <div class="space-y-8">
            <!-- Players Section -->
            <div class="bg-white rounded-lg shadow-sm p-6">
              <h2 class="text-2xl font-semibold text-gray-800 mb-4">Players</h2>
              <div class="space-y-4">
                <%= for player <- @players do %>
                  <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <span class="font-medium text-gray-900"><%= player %></span>
                    <%= if Map.has_key?(@claimed_players, player) do %>
                      <span class="text-sm text-green-600">Claimed</span>
                    <% else %>
                      <span class="text-sm text-gray-500">Unclaimed</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Current Monsters Section -->
            <div class="bg-white rounded-lg shadow-sm p-6">
              <h2 class="text-2xl font-semibold text-gray-800 mb-4">Current Monsters</h2>
              <%= if Enum.empty?(@monsters) do %>
                <p class="text-gray-500 italic">No monsters added yet</p>
              <% else %>
                <div class="space-y-3">
                  <%= for monster <- @monsters do %>
                    <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <span class="font-medium text-gray-900"><%= monster.name %></span>
                      <div class="text-sm text-gray-600">
                        <span class="mr-4">HP: <%= monster.hp %></span>
                        <span>Initiative: +<%= monster.initiative_bonus %></span>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Right Column -->
          <div class="space-y-8">
            <!-- Quick Add Monsters -->
            <div class="bg-white rounded-lg shadow-sm p-6">
              <h2 class="text-2xl font-semibold text-gray-800 mb-4">Quick Add Monsters</h2>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <%= for monster <- @monster_bank do %>
                  <button
                    type="button"
                    phx-click="add_monster_from_bank"
                    phx-value-name={monster.name}
                    phx-value-hp={monster.hp}
                    phx-value-initiative_bonus={monster.initiative_bonus}
                    class="flex flex-col p-4 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors duration-200"
                  >
                    <span class="text-lg font-semibold text-gray-900"><%= monster.name %></span>
                    <div class="text-sm text-gray-600 mt-1">
                      <span class="mr-3">HP: <%= monster.hp %></span>
                      <span>Initiative: +<%= monster.initiative_bonus %></span>
                    </div>
                  </button>
                <% end %>
              </div>
            </div>

            <!-- Custom Monster Form -->
            <div class="bg-white rounded-lg shadow-sm p-6">
              <h2 class="text-2xl font-semibold text-gray-800 mb-4">Add Custom Monster</h2>
              <form phx-submit="add_monster" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Monster Name</label>
                  <input 
                    type="text" 
                    name="name" 
                    required
                    placeholder="e.g., Dragon" 
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  />
                </div>
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">HP</label>
                    <input 
                      type="number" 
                      name="hp" 
                      required
                      placeholder="e.g., 45" 
                      class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Initiative Bonus</label>
                    <input 
                      type="number" 
                      name="initiative_bonus" 
                      required
                      placeholder="e.g., 2" 
                      class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                    />
                  </div>
                </div>
                <button 
                  type="submit" 
                  class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-2 px-4 rounded-md transition-colors duration-200"
                >
                  Add Monster
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def render_rolling(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-4xl">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-4xl font-bold text-gray-900">Waiting for Initiatives</h1>
          <div class="flex items-center gap-4">
            <%= if all_players_ready?(assigns) do %>
              <div class="text-green-600 font-medium">All players ready!</div>
            <% else %>
              <div class="text-gray-500">Waiting for players...</div>
            <% end %>
            <button 
              phx-click="start_combat"
              disabled={not all_players_ready?(assigns)}
              class={[
                "px-4 py-2 rounded-lg transition-colors duration-200",
                if(all_players_ready?(assigns), do: "bg-green-600 hover:bg-green-700 text-white", else: "bg-gray-300 text-gray-500 cursor-not-allowed")
              ]}
            >
              Start Combat
            </button>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm p-6">
          <h2 class="text-2xl font-semibold text-gray-800 mb-4">Player Status</h2>
          <div class="space-y-4">
            <%= for player <- @players do %>
              <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div class="flex items-center gap-4">
                  <span class="font-medium text-gray-900"><%= player %></span>
                  <%= cond do %>
                    <% not Map.has_key?(@claimed_players, player) -> %>
                      <span class="text-sm text-gray-500 bg-gray-100 px-2 py-1 rounded">Unclaimed</span>
                    <% not Map.has_key?(@player_initiatives, player) -> %>
                      <span class="text-sm text-yellow-600 bg-yellow-50 px-2 py-1 rounded">Waiting for roll</span>
                    <% true -> %>
                      <span class="text-sm text-green-600 bg-green-50 px-2 py-1 rounded">Ready</span>
                  <% end %>
                </div>
                <%= if Map.has_key?(@player_initiatives, player) do %>
                  <div class="flex items-center gap-2">
                    <span class="font-medium">Initiative: <%= @player_initiatives[player] %></span>
                    <button 
                      phx-click="clear_initiative" 
                      phx-value-player={player}
                      class="text-red-600 hover:text-red-800"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                      </svg>
                    </button>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Monster Preview -->
        <div class="mt-8 bg-white rounded-lg shadow-sm p-6">
          <h2 class="text-2xl font-semibold text-gray-800 mb-4">Monsters</h2>
          <%= if Enum.empty?(@monsters) do %>
            <div class="text-center py-8">
              <p class="text-gray-500">No monsters added yet</p>
              <button 
                phx-click="back_to_prep"
                class="mt-4 text-indigo-600 hover:text-indigo-800 font-medium"
              >
                Back to prep phase
              </button>
            </div>
          <% else %>
            <div class="space-y-3">
              <%= for monster <- @monsters do %>
                <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <span class="font-medium text-gray-900"><%= monster.name %></span>
                  <div class="text-sm text-gray-600">
                    <span class="mr-4">HP: <%= monster.hp %></span>
                    <span>Initiative: +<%= monster.initiative_bonus %></span>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Keep our existing combat view
  def render_combat(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-4xl">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-4xl font-bold text-gray-900">Combat Tracker</h1>
          <div class="space-x-4">
            <button 
              phx-click="next_turn" 
              class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition-colors duration-200"
            >
              Next Turn
            </button>
            <button 
              phx-click="reset_game"
              data-confirm="Are you sure you want to reset the game? This will clear all combat state."
              class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg transition-colors duration-200"
            >
              Reset
            </button>
          </div>
        </div>

        <div class="space-y-4">
          <%= for {creature, index} <- Enum.with_index(@combat_order) do %>
            <div class={[
              "bg-white rounded-lg shadow-sm p-4 border-2 transition-all duration-200",
              if(@current_turn == index, do: "border-indigo-500 ring-2 ring-indigo-200", else: "border-transparent")
            ]}>
              <div class="flex justify-between items-center">
                <div class="flex items-center space-x-4">
                  <%= if @current_turn == index do %>
                    <div class="w-2 h-2 bg-indigo-500 rounded-full"></div>
                  <% end %>
                  <span class="font-semibold text-lg text-gray-900">
                    <%= creature.name %>
                  </span>
                  <span class="text-gray-600">
                    Initiative: <%= creature.initiative %>
                  </span>
                </div>
                <div class="flex items-center space-x-3">
                  <button 
                    phx-click="modify_hp" 
                    phx-value-amount="-1" 
                    phx-value-index={index}
                    class="bg-red-100 hover:bg-red-200 text-red-700 w-8 h-8 rounded-full flex items-center justify-center transition-colors duration-200"
                  >
                    -
                  </button>
                  <span class="w-20 text-center font-medium">
                    <%= creature.hp %>/<%= creature.max_hp %>
                  </span>
                  <button 
                    phx-click="modify_hp" 
                    phx-value-amount="1" 
                    phx-value-index={index}
                    class="bg-green-100 hover:bg-green-200 text-green-700 w-8 h-8 rounded-full flex items-center justify-center transition-colors duration-200"
                  >
                    +
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_info({:state_updated, new_state}, socket) do
    {:noreply, assign(socket, Map.merge(new_state, %{monster_bank: @monster_bank}))}
  end

  def handle_event("start_rolling", _params, socket) do
    new_state = Map.put(socket.assigns, :phase, :rolling)
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("add_monster", params, socket) do
    monster = %{
      name: params["name"],
      hp: String.to_integer(params["hp"]),
      max_hp: String.to_integer(params["hp"]),
      initiative_bonus: String.to_integer(params["initiative_bonus"])
    }
    new_state = Map.update!(socket.assigns, :monsters, &[monster | &1])
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("add_monster_from_bank", params, socket) do
    monster = %{
      name: params["name"],
      hp: String.to_integer(params["hp"]),
      max_hp: String.to_integer(params["hp"]),
      initiative_bonus: String.to_integer(params["initiative_bonus"])
    }
    new_state = Map.update!(socket.assigns, :monsters, &[monster | &1])
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("start_combat", _params, socket) do
    case Enum.all?(socket.assigns.players, &Map.has_key?(socket.assigns.player_initiatives, &1)) do
      false ->
        {:noreply, socket}
      true ->
        monsters_with_initiative = Enum.map(socket.assigns.monsters, fn monster ->
          initiative = :rand.uniform(20) + monster.initiative_bonus
          Map.put(monster, :initiative, initiative)
        end)

        players = Enum.map(socket.assigns.players, fn player ->
          initiative = socket.assigns.player_initiatives[player]
          %{
            name: player,
            initiative: String.to_integer(initiative),
            hp: 100,
            max_hp: 100,
            type: :player
          }
        end)

        combat_order = (players ++ monsters_with_initiative)
                      |> Enum.sort_by(& &1.initiative, :desc)

        new_state = Map.merge(socket.assigns, %{
          phase: :combat,
          combat_order: combat_order,
          current_turn: 0
        })
        Workspace.GameState.set_state(new_state)
        {:noreply, socket}
    end
  end

  def handle_event("modify_hp", %{"amount" => amount, "index" => index}, socket) do
    index = String.to_integer(index)
    amount = String.to_integer(amount)

    new_state = Map.update!(socket.assigns, :combat_order, fn order ->
      List.update_at(order, index, fn creature ->
        Map.update!(creature, :hp, &max(0, &1 + amount))
      end)
    end)

    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("next_turn", _params, socket) do
    new_state = Map.update!(socket.assigns, :current_turn, fn current ->
      rem(current + 1, length(socket.assigns.combat_order))
    end)
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("reset_game", _params, socket) do
    new_state = %{
      phase: :prep,
      players: ["Gandalf", "Aragorn", "Legolas"],
      claimed_players: %{},  # Added this line
      player_initiatives: %{},
      monsters: [],
      combat_order: [],
      current_turn: 0
    }
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("clear_initiative", %{"player" => player}, socket) do
    new_initiatives = Map.delete(socket.assigns.player_initiatives, player)
    new_state = Map.put(socket.assigns, :player_initiatives, new_initiatives)
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("back_to_prep", _params, socket) do
    new_state = Map.put(socket.assigns, :phase, :prep)
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  # Helper function to check if all players are ready
  defp all_players_ready?(assigns) do
    claimed_players = Map.keys(assigns.claimed_players)
    initiatives = Map.keys(assigns.player_initiatives)

    # All claimed players have submitted initiatives
    Enum.all?(claimed_players, &(&1 in initiatives))
  end
end