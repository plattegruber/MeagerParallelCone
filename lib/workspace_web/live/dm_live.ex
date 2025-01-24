import WorkspaceWeb.GameComponents

defmodule WorkspaceWeb.DMLive do
  use WorkspaceWeb, :live_view
  alias WorkspaceWeb.DM.{PrepComponent, RollingComponent, CombatComponent}

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
      :prep -> PrepComponent.prep(assigns)
      :rolling -> RollingComponent.rolling(assigns)
      :combat -> CombatComponent.combat(assigns)
    end
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
end