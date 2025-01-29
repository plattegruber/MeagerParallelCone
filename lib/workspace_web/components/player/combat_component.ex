# lib/workspace_web/components/player/combat_component.ex
defmodule WorkspaceWeb.Player.CombatComponent do
  use Phoenix.Component
  import WorkspaceWeb.GameComponents
  import WorkspaceWeb.CoreComponents
  import WorkspaceWeb.HistoryPanelComponent
  import WorkspaceWeb.RoleNotificationComponent
  alias Phoenix.LiveView.JS

  def combat(assigns) do
  my_player = get_my_player(assigns.claimed_players, assigns.device_id)
  current_role = determine_player_role(assigns.combat_order, assigns.current_turn, my_player)

  assigns = assign(assigns, :role, current_role)
      
  ~H"""
    <div class="min-h-screen bg-white sm:bg-gray-50">  <%!-- Make bg white on mobile --%>
      <.notification role={@role} show={@show_notification} />
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-0 sm:px-4">  <%!-- Remove padding on mobile --%>
        <div class="lg:flex lg:gap-8 lg:max-w-6xl lg:mx-auto">
          <div class="flex-1 min-w-0">
            <div class="max-w-4xl px-4 sm:px-0">  <%!-- Move padding to inner container --%>
              <h1 class="text-2xl sm:text-4xl font-bold text-gray-900 mb-4 sm:mb-8 mt-4">Combat</h1>
              <div class="space-y-3 sm:space-y-4">
                <%= for {creature, index} <- Enum.with_index(@combat_order) do %>
                  <.creature_card 
                    creature={creature}
                    index={index}
                    current_turn={@current_turn}
                    claimed_players={@claimed_players}
                    device_id={@device_id}
                  />
                <% end %>
              </div>
            </div>
          </div>
          <div class="lg:w-80 flex-shrink-0 mt-6 sm:mt-8 lg:mt-0"> <%!-- Adjust margin top --%>
            <.history_panel combat_history={@combat_history} is_dm={@is_dm} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def creature_card(assigns) do
    ~H"""
    <div class={[
      "bg-white rounded-lg shadow-sm p-3 sm:p-4 border-2 transition-all duration-200",
      if(@current_turn == @index, do: "border-indigo-500 ring-2 ring-indigo-200", else: "border-transparent"),
      if(Map.get(@creature, :dead, false), do: "opacity-50 bg-gray-50")
    ]}>
      <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center space-y-3 sm:space-y-0">
        <.creature_info creature={@creature} current_turn={@current_turn} index={@index} />
        <.health_display
          creature={@creature}
          index={@index}
          claimed_players={@claimed_players}
          device_id={@device_id}
        />
      </div>
    </div>
    """
  end

  def creature_info(assigns) do
    ~H"""
    <div class="flex items-center space-x-2 sm:space-x-4">
      <%= if @current_turn == @index do %>
        <div class="w-2 h-2 bg-indigo-500 rounded-full flex-shrink-0"></div>
      <% end %>
      <span class={[
        "font-semibold text-base sm:text-lg truncate",
        if(Map.get(@creature, :dead, false), do: "text-gray-500 line-through", else: "text-gray-900")
      ]}>
        <%= @creature.name %>
      </span>
      <span class="text-sm sm:text-base text-gray-600 flex-shrink-0">
        Initiative: <%= @creature.initiative %>
      </span>
    </div>
    """
  end

  def health_display(assigns) do
    ~H"""
    <div class="flex items-center space-x-2 sm:space-x-3">
      <button 
        phx-click={show_modal("hp-modal-#{@index}")}
        phx-value-index={@index}
        class="bg-gray-100 hover:bg-gray-200 text-gray-700 px-2 sm:px-3 py-1 rounded-md flex items-center justify-center transition-colors duration-200 text-sm sm:text-base whitespace-nowrap"
      >
        Modify HP
      </button>
  
      <%= if is_my_player?(@creature.name, @claimed_players, @device_id) do %>
        <.player_health_display creature={@creature} index={@index} />
      <% else %>
        <.health_indicator creature={@creature} index={@index} />
      <% end %>
  
      <.hp_modal index={@index} />
    </div>
    """
  end

  def player_health_display(assigns) do
    ~H"""
    <div 
      id={"hp-display-#{@index}"}
      class="w-20 text-center font-medium"
    >
      <span class="inline-block">
        <%= @creature.hp %>/<%= @creature.max_hp %>
      </span>
    </div>
    """
  end

  def health_indicator(assigns) do
    ~H"""
    <div 
      id={"hp-indicator-#{@index}"}
      class="w-20 flex items-center justify-center"
    >
      <div 
        class="w-4 h-4 rounded-full"
        style={get_health_indicator_color(@creature.hp, @creature.max_hp)}
      >
      </div>
    </div>
    """
  end

  def hp_modal(assigns) do
    ~H"""
    <div id={"hp-modal-#{@index}"} class="relative z-50 hidden">
      <div id={"hp-modal-#{@index}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto px-4 py-6 sm:px-6"
        aria-labelledby={"hp-modal-#{@index}-title"}
        aria-describedby={"hp-modal-#{@index}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-sm">
            <div class="rounded-lg bg-white shadow-lg">
              <div class="p-4 sm:p-6">
                <h3 class="text-lg font-medium text-gray-900 mb-4" id={"hp-modal-#{@index}-title"}>
                  Modify HP
                </h3>
  
                <form phx-submit={JS.push("modify_hp_amount") |> hide_modal("hp-modal-#{@index}")}>
                  <input type="hidden" name="index" value={@index} />
                  
                  <div class="space-y-4">
                    <div class="flex items-center justify-center space-x-6">
                      <label class="inline-flex items-center">
                        <input
                          type="radio"
                          name="type"
                          value="damage"
                          class="form-radio text-red-600 h-5 w-5"
                          checked
                        />
                        <span class="ml-2 text-gray-700">Damage</span>
                      </label>
                      <label class="inline-flex items-center">
                        <input
                          type="radio"
                          name="type"
                          value="heal"
                          class="form-radio text-green-600 h-5 w-5"
                        />
                        <span class="ml-2 text-gray-700">Heal</span>
                      </label>
                    </div>
  
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Amount</label>
                      <input
                        type="number"
                        name="amount"
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-base py-2"
                        required
                        min="0"
                        inputmode="numeric"
                        pattern="[0-9]*"
                      />
                    </div>
                  </div>
  
                  <div class="mt-6 flex items-center justify-end space-x-3">
                    <button
                      type="button"
                      class="rounded-md border border-gray-300 bg-white py-2 px-4 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 min-w-[80px]"
                      phx-click={hide_modal("hp-modal-#{@index}")}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 min-w-[80px]"
                    >
                      Apply
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions
  defp is_my_player?(player, claimed_players, device_id) do
    claimed_players[player] == device_id
  end

  defp get_health_indicator_color(current_hp, max_hp) do
    percentage = min(current_hp / max_hp * 100, 100)  # Cap at 100%
    cond do
      percentage > 75 ->
        # Green to Yellow transition
        progress = (100 - percentage) / 25
        start_color = interpolate_color({34, 197, 94}, {234, 179, 8}, progress)
        "background-color: rgb(#{start_color.r}, #{start_color.g}, #{start_color.b})"
      percentage > 50 ->
        # Yellow to Orange transition
        progress = (75 - percentage) / 25
        start_color = interpolate_color({234, 179, 8}, {249, 115, 22}, progress)
        "background-color: rgb(#{start_color.r}, #{start_color.g}, #{start_color.b})"
      percentage > 25 ->
        # Orange to Red transition
        progress = (50 - percentage) / 25
        start_color = interpolate_color({249, 115, 22}, {239, 68, 68}, progress)
        "background-color: rgb(#{start_color.r}, #{start_color.g}, #{start_color.b})"
      percentage > 5 ->
        # Red to Dark Red transition
        progress = (25 - percentage) / 20
        start_color = interpolate_color({239, 68, 68}, {127, 29, 29}, progress)
        "background-color: rgb(#{start_color.r}, #{start_color.g}, #{start_color.b})"
      true ->
        # Critical is solid dark red
        "background-color: rgb(127, 29, 29)"
    end
  end

  defp interpolate_color({r1, g1, b1}, {r2, g2, b2}, progress) do
    %{
      r: round(r1 + (r2 - r1) * progress),
      g: round(g1 + (g2 - g1) * progress),
      b: round(b1 + (b2 - b1) * progress)
    }
  end

  def determine_player_role(combat_order, current_turn, player_name) do
    # Handle empty combat order first
    if Enum.empty?(combat_order) do
      "standby"
    else
      player_index = Enum.find_index(combat_order, & &1.name == player_name)
      player_count = Enum.count(combat_order, & Map.get(&1, :type) == :player)
      
      case player_index do
        nil -> "standby"
        ^current_turn -> "active"
        _index ->
          cond do
            player_count == 1 -> "standby"
            player_count == 2 ->
              next_player_index = find_next_player_turn(combat_order, current_turn)
              if player_index == next_player_index, do: "on-deck", else: "standby"
            true ->
              next_player_index = find_next_player_turn(combat_order, current_turn)
              prev_player_index = find_prev_player_turn(combat_order, current_turn)
              
              cond do
                player_index == next_player_index -> "on-deck"
                player_index == prev_player_index -> "scribe"
                true -> "standby"
              end
          end
      end
    end
  end
  
  defp find_next_player_turn(combat_order, current_turn) do
    combat_order
    |> Enum.with_index()
    |> Enum.drop(current_turn + 1)
    |> Enum.concat(Enum.with_index(combat_order))
    |> Enum.find_value(fn {creature, index} -> 
      if Map.get(creature, :type) == :player, do: index
    end)
  end
  
  defp find_prev_player_turn(combat_order, current_turn) do
    combat_order
    |> Enum.with_index()
    |> Enum.take(current_turn)
    |> Enum.reverse()
    |> Enum.find_value(fn {creature, index} -> 
      if Map.get(creature, :type) == :player, do: index
    end)
  end

  def handle_info(:hide_notification, socket) do
    {:noreply, assign(socket, :show_notification, false)}
  end

  def get_my_player(claimed_players, device_id) do
    case Enum.find(claimed_players, fn {_player, id} -> id == device_id end) do
      {player, _} -> player
      nil -> nil
    end
  end
end