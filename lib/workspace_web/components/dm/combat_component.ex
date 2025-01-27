# lib/workspace_web/components/dm/combat_component.ex
defmodule WorkspaceWeb.DM.CombatComponent do
  use Phoenix.Component
  import WorkspaceWeb.GameComponents
  import WorkspaceWeb.HistoryPanelComponent

  def combat(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="lg:flex lg:gap-8">
        <div class="flex-1">
          <div class="container mx-auto px-4 max-w-4xl">
            <.header_section />
            <.combat_order combat_order={@combat_order} current_turn={@current_turn} />
          </div>
        </div>
        <.history_panel combat_history={@combat_history} is_dm={@is_dm} />
      </div>
    </div>
    """
  end

  def header_section(assigns) do
    ~H"""
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
    """
  end

  def combat_order(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= for {creature, index} <- Enum.with_index(@combat_order) do %>
        <.creature_card creature={creature} index={index} current_turn={@current_turn} />
      <% end %>
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
          <%= if Map.get(@creature, :type) == :player do %>
            <button
              type="button"
              phx-click="unlink_player"
              phx-value-player={@creature.name}
              class="text-sm text-red-600 hover:text-red-700"
            >
              Unlink
            </button>
          <% end %>
        </div>
        <div class="flex items-center space-x-3">
          <button 
            phx-click="toggle_dead"
            phx-value-index={@index}
            class={[
              "px-3 py-1 rounded-md text-sm transition-colors duration-200",
              if(Map.get(@creature, :dead, false), do: "bg-green-100 hover:bg-green-200 text-green-700", else: "bg-gray-100 hover:bg-gray-200 text-gray-700")
            ]}
          >
            <%= if Map.get(@creature, :dead, false), do: "Mark Alive", else: "Mark Dead" %>
          </button>
          <.hp_controls creature={@creature} index={@index} />
        </div>
      </div>
    </div>
    """
  end

  def hp_controls(assigns) do
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
      <div 
        phx-hook="HPAnimation"
        id={"hp-display-#{@index}"}
        class="w-20 text-center font-medium group"
      >
        <span class="inline-block transition-all duration-500 group-[.animate]:animate-bounce-once">
          <%= @creature.hp %>/<%= @creature.max_hp %>
        </span>
      </div>
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
end