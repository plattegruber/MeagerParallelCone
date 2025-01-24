import WorkspaceWeb.GameComponents

defmodule WorkspaceWeb.PlayerLive do
  use WorkspaceWeb, :live_view

  def mount(_params, _session, socket) do
    device_id = generate_device_id()
    
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Workspace.PubSub, "game_state")
      state = Workspace.GameState.get_state()
      {:ok, assign(socket, Map.merge(state, %{device_id: device_id, is_dm: false}))}
    else
      initial_state = %{
        phase: :prep,
        is_dm: false,  # Added this line
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
      :prep -> render_prep(assigns)
      :rolling -> render_rolling(assigns)
      :combat -> render_combat(assigns)
    end
  end

  # For now, just show basic info in each phase
  def render_prep(assigns) do
    ~H"""
    <div id="device-id-manager" phx-hook="DeviceId"></div>
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-4xl">
        <h1 class="text-4xl font-bold text-gray-900 mb-8">Choose Your Character</h1>
        
        <div class="bg-white rounded-lg shadow-sm p-6">
          <div class="space-y-4">
            <%= for player <- @players do %>
              <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <span class="font-medium text-gray-900"><%= player %></span>
                
                <%= if is_player_claimed?(player, @claimed_players) do %>
                  <%= if is_my_player?(player, @claimed_players, @device_id) do %>
                    <div class="text-green-600 font-medium">
                      Your Character
                    </div>
                  <% else %>
                    <div class="text-gray-500">
                      Already Claimed
                    </div>
                  <% end %>
                <% else %>
                  <button 
                    phx-click="claim_player"
                    phx-value-player={player}
                    class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition-colors duration-200"
                  >
                    Choose Character
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
          
          <%= if has_claimed_player?(@claimed_players, @device_id) do %>
            <div class="mt-8 text-center text-gray-600">
              Waiting for other players and DM...
            </div>
          <% end %>
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
        <h1 class="text-4xl font-bold text-gray-900 mb-8">Roll Initiative</h1>

        <div class="bg-white rounded-lg shadow-sm p-6">
          <%= if has_claimed_player?(@claimed_players, @device_id) do %>
            <div class="space-y-6">
              <%= for player <- @players do %>
                <%= if is_my_player?(player, @claimed_players, @device_id) do %>
                  <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <span class="font-medium text-gray-900"><%= player %></span>
                    <%= if Map.has_key?(@player_initiatives, player) do %>
                      <div class="text-green-600 font-medium">
                        Initiative: <%= @player_initiatives[player] %>
                      </div>
                    <% else %>
                      <form phx-submit="submit_initiative" class="flex items-center gap-2">
                        <input
                          type="number"
                          name="initiative"
                          placeholder="Enter roll"
                          required
                          class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                        />
                        <input type="hidden" name="player" value={player} />
                        <button 
                          type="submit"
                          class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition-colors duration-200"
                        >
                          Submit
                        </button>
                      </form>
                    <% end %>
                  </div>
                <% else %>
                  <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <span class="font-medium text-gray-900"><%= player %></span>
                    <%= if Map.has_key?(@player_initiatives, player) do %>
                      <div class="text-green-600">Ready</div>
                    <% else %>
                      <div class="text-gray-500">Waiting...</div>
                    <% end %>
                  </div>
                <% end %>
              <% end %>

              <%= if Map.has_key?(@player_initiatives, get_my_player(@claimed_players, @device_id)) do %>
                <div class="mt-8 text-center text-gray-600">
                  Waiting for other players...
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="text-center py-8">
              <p class="text-gray-600 mb-4">You haven't chosen a character yet.</p>
              <a href="/" class="text-indigo-600 hover:text-indigo-800 font-medium">
                Go back to character selection
              </a>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

def render_combat(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-4xl">
        <h1 class="text-4xl font-bold text-gray-900 mb-8">Combat</h1>
        
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

                  <%= if is_my_player?(creature.name, @claimed_players, @device_id) do %>
                    <span class="w-20 text-center font-medium">
                      <%= creature.hp %>/<%= creature.max_hp %>
                    </span>
                  <% else %>
                    <div class="w-20 flex items-center justify-center">
                      <div class={[
                        "w-4 h-4 rounded-full",
                        get_health_indicator_color(creature.hp, creature.max_hp)
                      ]}></div>
                    </div>
                  <% end %>

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
    {:noreply, assign(socket, Map.put(new_state, :device_id, socket.assigns.device_id))}
  end

  defp generate_device_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end

  # Handle the device_id coming back from localStorage
  def handle_event("device_id_set", %{"device_id" => ""}, socket) do
    # No stored device_id, generate a new one
    device_id = generate_device_id()
    {:noreply, push_event(socket, "store_device_id", %{device_id: device_id})
      |> assign(:device_id, device_id)}
  end


  def handle_event("device_id_set", %{"device_id" => device_id}, socket) do
    # Got a stored device_id
    {:noreply, assign(socket, :device_id, device_id)}
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

  defp get_my_player(claimed_players, device_id) do
    claimed_players
    |> Enum.find(fn {_player, id} -> id == device_id end)
    |> case do
      {player, _} -> player
      nil -> nil
    end
  end

  def handle_event("claim_player", %{"player" => player}, socket) do
    # Only allow claiming if the player hasn't claimed anyone yet
    if not has_claimed_player?(socket.assigns.claimed_players, socket.assigns.device_id) do
      # Only claim if the player isn't already claimed
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

  defp get_health_indicator_color(current_hp, max_hp) do
    percentage = current_hp / max_hp * 100

    cond do
      percentage > 75 -> "bg-green-500"
      percentage > 50 -> "bg-yellow-500"
      percentage > 25 -> "bg-orange-500"
      percentage > 5 -> "bg-red-500"
      true -> "bg-red-900"
    end
  end
end