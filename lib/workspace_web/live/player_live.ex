# lib/workspace_web/live/player_live.ex
defmodule WorkspaceWeb.PlayerLive do
  use WorkspaceWeb, :live_view
  alias WorkspaceWeb.Player.{PrepComponent, RollingComponent, CombatComponent}

  def mount(_params, _session, socket) do
    device_id = generate_device_id()
    
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Workspace.PubSub, "game_state")
      state = Workspace.GameState.get_state()
      {:ok, assign(socket, Map.merge(state, %{device_id: device_id, is_dm: false}))}
    else
      initial_state = %{
        phase: :prep,
        is_dm: false,
        players: ["Gandalf", "Aragorn", "Legolas"],
        claimed_players: %{},
        player_initiatives: %{},
        monsters: [],
        combat_order: [],
        current_turn: 0,
        device_id: device_id
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
    {:noreply, assign(socket, Map.put(new_state, :device_id, socket.assigns.device_id))}
  end

  # Group all handle_event functions together
  def handle_event("device_id_set", %{"device_id" => ""}, socket) do
    device_id = generate_device_id()
    {:noreply, push_event(socket, "store_device_id", %{device_id: device_id})
      |> assign(:device_id, device_id)}
  end

  def handle_event("device_id_set", %{"device_id" => device_id}, socket) do
    {:noreply, assign(socket, :device_id, device_id)}
  end

  def handle_event("claim_player", %{"player" => player}, socket) do
    if not has_claimed_player?(socket.assigns.claimed_players, socket.assigns.device_id) do
      if not is_player_claimed?(player, socket.assigns.claimed_players) do
        new_claimed_players = Map.put(socket.assigns.claimed_players, player, socket.assigns.device_id)
        new_state = Map.put(socket.assigns, :claimed_players, new_claimed_players)
        Workspace.GameState.set_state(new_state)
      end
    end
    {:noreply, socket}
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

  def handle_event("submit_initiative", %{"initiative" => initiative, "player" => player} = _params, socket) do
    if is_my_player?(player, socket.assigns.claimed_players, socket.assigns.device_id) do
      new_initiatives = Map.put(socket.assigns.player_initiatives, player, initiative)
      new_state = Map.put(socket.assigns, :player_initiatives, new_initiatives)
      Workspace.GameState.set_state(new_state)
    end
    {:noreply, socket}
  end

  # Helper functions used by event handlers
  defp generate_device_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end

  defp is_player_claimed?(player, claimed_players) do
    Map.has_key?(claimed_players, player)
  end

  defp is_my_player?(player, claimed_players, device_id) do
    claimed_players[player] == device_id
  end

  defp has_claimed_player?(claimed_players, device_id) do
    Enum.any?(claimed_players, fn {_player, id} -> id == device_id end)
  end
end