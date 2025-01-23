defmodule WorkspaceWeb.EncounterLive do
  use WorkspaceWeb, :live_view

  def mount(_params, _session, socket) do
    initial_state = %{
      page: :setup,
      players: ["Gandalf", "Aragorn", "Legolas"],
      player_initiatives: %{},
      monsters: [],
      combat_order: [],
      current_turn: 0
    }
  
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Workspace.PubSub, "game_state")
      state = Workspace.GameState.get_state()
      {:ok, assign(socket, state)}  # This is fine because state is filtered
    else
      {:ok, assign(socket, initial_state)}  # This is fine because we control initial_state
    end
  end


  def render(assigns) do
    case assigns.page do
      :setup -> render_setup(assigns)
      :combat -> render_combat(assigns)
    end
  end

  def render_setup(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">Setup Encounter</h1>
      
      <div class="mb-6">
        <h2 class="text-xl mb-2">Players</h2>
        <%= for player <- @players do %>
          <div class="mb-2">
            <label><%= player %>'s Initiative:</label>
            <input 
              type="number" 
              phx-blur="set_player_initiative" 
              value={Map.get(@player_initiatives, player)} 
              phx-value-player={player} 
              class="border p-1"
            />
          </div>
        <% end %>
      </div>

      <div class="mb-6">
        <h2 class="text-xl mb-2">Add Monster</h2>
        <form phx-submit="add_monster">
          <input type="text" name="name" placeholder="Monster Name" class="border p-1 mr-2"/>
          <input type="number" name="hp" placeholder="HP" class="border p-1 mr-2"/>
          <input type="number" name="initiative_bonus" placeholder="Initiative Bonus" class="border p-1 mr-2"/>
          <button type="submit" class="bg-blue-500 text-white px-4 py-1 rounded">Add</button>
        </form>

        <div class="mt-4">
          <%= for monster <- @monsters do %>
            <div class="mb-2">
              <%= monster.name %> (HP: <%= monster.hp %>, Initiative Bonus: <%= monster.initiative_bonus %>)
            </div>
          <% end %>
        </div>
      </div>

      <button phx-click="start_combat" type="button" class="bg-green-500 text-white px-4 py-2 rounded">Start Combat</button>
    </div>
    """
  end

  def render_combat(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">Combat</h1>
      
      <div class="space-y-2">
        <%= for {creature, index} <- Enum.with_index(@combat_order) do %>
          <div class={["p-4 border rounded", if(@current_turn == index, do: "bg-yellow-100")]}>
            <div class="flex justify-between items-center">
              <span class="font-bold"><%= creature.name %> (Initiative: <%= creature.initiative %>)</span>
              <div>
                <button phx-click="modify_hp" phx-value-amount="-1" phx-value-index={index} class="bg-red-500 text-white px-2 rounded">-</button>
                <span class="mx-2"><%= creature.hp %>/<%= creature.max_hp %></span>
                <button phx-click="modify_hp" phx-value-amount="1" phx-value-index={index} class="bg-green-500 text-white px-2 rounded">+</button>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <button phx-click="next_turn" class="mt-4 bg-blue-500 text-white px-4 py-2 rounded">
        Next Turn
      </button>
      <button 
        phx-click="reset_game" 
        data-confirm="Are you sure you want to reset the game? This will clear all combat state."
        class="mt-4 ml-4 bg-red-500 text-white px-4 py-2 rounded">
        Reset Game
      </button>
    </div>
    """
  end

  def handle_info({:state_updated, new_state}, socket) do
    {:noreply, assign(socket,
      page: new_state.page,
      players: new_state.players,
      player_initiatives: new_state.player_initiatives,
      monsters: new_state.monsters,
      combat_order: new_state.combat_order,
      current_turn: new_state.current_turn
    )}
  end

  def handle_event("reset_game", _params, socket) do
    new_state = %{
      page: :setup,
      players: ["Gandalf", "Aragorn", "Legolas"],
      player_initiatives: %{},
      monsters: [],
      combat_order: [],
      current_turn: 0
    }
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("set_player_initiative", %{"player" => player, "value" => ""}, socket) do
    new_state = Map.update!(socket.assigns, :player_initiatives, &Map.delete(&1, player))
    Workspace.GameState.set_state(new_state)
    {:noreply, socket}
  end

  def handle_event("set_player_initiative", %{"player" => player, "value" => value}, socket) do
    new_state = Map.update!(socket.assigns, :player_initiatives, &Map.put(&1, player, value))
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
          page: :combat,
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
end