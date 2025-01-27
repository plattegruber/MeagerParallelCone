# lib/workspace_web/components/player/combat_component.ex
defmodule WorkspaceWeb.Player.CombatComponent do
  use Phoenix.Component
  import WorkspaceWeb.GameComponents
  import WorkspaceWeb.CoreComponents
  import WorkspaceWeb.HistoryPanelComponent
  alias Phoenix.LiveView.JS

  def combat(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="lg:flex lg:gap-8">
        <div class="flex-1">
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
        <.history_panel combat_history={@combat_history} is_dm={@is_dm} />
      </div>
    </div>
    """
  end

  def creature_card(assigns) do
  ~H"""
    <div class={[
      "bg-white rounded-lg shadow-sm p-4 border-2 transition-all duration-200",
      if(@current_turn == @index, do: "border-indigo-500 ring-2 ring-indigo-200", else: "border-transparent"),
      if(Map.get(@creature, :dead, false), do: "opacity-50 bg-gray-50")
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
      <span class={[
        "font-semibold text-lg",
        if(Map.get(@creature, :dead, false), do: "text-gray-500 line-through", else: "text-gray-900")
      ]}>
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
        phx-click={show_modal("hp-modal-#{@index}")}
        phx-value-index={@index}
        class="bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1 rounded-md flex items-center justify-center transition-colors duration-200"
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

  def hp_modal(assigns) do
    ~H"""
    <div id={"hp-modal-#{@index}"} class="relative z-50 hidden">
      <div id={"hp-modal-#{@index}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"hp-modal-#{@index}-title"}
        aria-describedby={"hp-modal-#{@index}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-sm p-4 sm:p-6">
            <div class="rounded-lg bg-white shadow-lg">
              <div class="p-6">
                <h3 class="text-lg font-medium text-gray-900 mb-4" id={"hp-modal-#{@index}-title"}>
                  Modify HP
                </h3>
  
                <form phx-submit={JS.push("modify_hp_amount") |> hide_modal("hp-modal-#{@index}")}>
                  <input type="hidden" name="index" value={@index} />
                  
                  <div class="space-y-4">
                    <div class="flex items-center justify-center space-x-4">
                      <label class="inline-flex items-center">
                        <input
                          type="radio"
                          name="type"
                          value="damage"
                          class="form-radio text-red-600"
                          checked
                        />
                        <span class="ml-2 text-gray-700">Damage</span>
                      </label>
                      <label class="inline-flex items-center">
                        <input
                          type="radio"
                          name="type"
                          value="heal"
                          class="form-radio text-green-600"
                        />
                        <span class="ml-2 text-gray-700">Heal</span>
                      </label>
                    </div>
  
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Amount</label>
                      <input
                        type="number"
                        name="amount"
                        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
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
                      class="rounded-md border border-gray-300 bg-white py-2 px-4 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                      phx-click={hide_modal("hp-modal-#{@index}")}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      class="rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
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