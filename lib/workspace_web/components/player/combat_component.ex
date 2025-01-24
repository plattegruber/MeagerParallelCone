# lib/workspace_web/components/player/combat_component.ex
defmodule WorkspaceWeb.Player.CombatComponent do
  use Phoenix.Component
  import WorkspaceWeb.GameComponents

  def combat(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-4xl">
        <h1 class="text-4xl font-bold text-gray-900 mb-8">Combat</h1>

        <div class="space-y-4">
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
    """
  end

  def creature_card(assigns) do
    ~H"""
    <div class={[
      "bg-white rounded-lg shadow-sm p-4 border-2 transition-all duration-200",
      if(@current_turn == @index, do: "border-indigo-500 ring-2 ring-indigo-200", else: "border-transparent")
    ]}>
      <div class="flex justify-between items-center">
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
    <div class="flex items-center space-x-4">
      <%= if @current_turn == @index do %>
        <div class="w-2 h-2 bg-indigo-500 rounded-full"></div>
      <% end %>
      <span class="font-semibold text-lg text-gray-900">
        <%= @creature.name %>
      </span>
      <span class="text-gray-600">
        Initiative: <%= @creature.initiative %>
      </span>
    </div>
    """
  end

  def health_display(assigns) do
    ~H"""
    <div class="flex items-center space-x-3">
      <button 
        phx-click="modify_hp" 
        phx-value-amount="-1" 
        phx-value-index={@index}
        class="bg-red-100 hover:bg-red-200 text-red-700 w-8 h-8 rounded-full flex items-center justify-center transition-colors duration-200"
      >
        -
      </button>

      <%= if is_my_player?(@creature.name, @claimed_players, @device_id) do %>
        <.player_health_display creature={@creature} index={@index} />
      <% else %>
        <.health_indicator creature={@creature} index={@index} />
      <% end %>

      <button 
        phx-click="modify_hp" 
        phx-value-amount="1" 
        phx-value-index={@index}
        class="bg-green-100 hover:bg-green-200 text-green-700 w-8 h-8 rounded-full flex items-center justify-center transition-colors duration-200"
      >
        +
      </button>
    </div>
    """
  end

  def player_health_display(assigns) do
    ~H"""
    <div 
      phx-hook="HPAnimation"
      id={"hp-display-#{@index}"}
      class="w-20 text-center font-medium transition-all duration-500 group"
    >
      <span class="inline-block group-[.animate]:animate-bounce-once">
        <%= @creature.hp %>/<%= @creature.max_hp %>
      </span>
    </div>
    """
  end

  def health_indicator(assigns) do
    ~H"""
    <div 
      phx-hook="HPAnimation"
      id={"hp-indicator-#{@index}"}
      class="w-20 flex items-center justify-center group"
    >
      <div 
        class="w-4 h-4 rounded-full transition-all duration-200 group-[.animate]:scale-110"
        style={get_health_indicator_color(@creature.hp, @creature.max_hp)}
      >
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
    end  # Added this missing end
  end

  # lib/workspace_web/components/player/combat_component.ex
  # Add this at the bottom of the module:

  defp interpolate_color({r1, g1, b1}, {r2, g2, b2}, progress) do
    %{
      r: round(r1 + (r2 - r1) * progress),
      g: round(g1 + (g2 - g1) * progress),
      b: round(b1 + (b2 - b1) * progress)
    }
  end
end