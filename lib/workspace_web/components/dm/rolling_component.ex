# lib/workspace_web/components/dm/rolling_component.ex
defmodule WorkspaceWeb.DM.RollingComponent do
  use Phoenix.Component
  import WorkspaceWeb.GameComponents

  def rolling(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-4xl">
        <.header_section all_players_ready?={all_players_ready?(assigns)} />
        <.player_status_section
          players={@players}
          claimed_players={@claimed_players}
          player_initiatives={@player_initiatives}
        />
        <.monster_preview_section monsters={@monsters} />
      </div>
    </div>
    """
  end

  def header_section(assigns) do
    ~H"""
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-4xl font-bold text-gray-900">Waiting for Initiatives</h1>
      <div class="flex items-center gap-4">
        <%= if @all_players_ready? do %>
          <div class="text-green-600 font-medium">All players ready!</div>
        <% else %>
          <div class="text-gray-500">Waiting for players...</div>
        <% end %>
        <button 
          phx-click="start_combat"
          disabled={not @all_players_ready?}
          class={[
            "px-4 py-2 rounded-lg transition-colors duration-200",
            if(@all_players_ready?, do: "bg-green-600 hover:bg-green-700 text-white", else: "bg-gray-300 text-gray-500 cursor-not-allowed")
          ]}
        >
          Start Combat
        </button>
      </div>
    </div>
    """
  end

  def player_status_section(assigns) do
    ~H"""
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
                  <div class="flex items-center gap-3">
                    <span class="text-sm text-yellow-600 bg-yellow-50 px-2 py-1 rounded">Waiting for roll</span>
                    <button
                      type="button"
                      phx-click="unlink_player"
                      phx-value-player={player}
                      class="text-sm text-red-600 hover:text-red-700"
                    >
                      Unlink
                    </button>
                  </div>
                <% true -> %>
                  <div class="flex items-center gap-3">
                    <span class="text-sm text-green-600 bg-green-50 px-2 py-1 rounded">Ready</span>
                    <button
                      type="button"
                      phx-click="unlink_player"
                      phx-value-player={player}
                      class="text-sm text-red-600 hover:text-red-700"
                    >
                      Unlink
                    </button>
                  </div>
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
    """
  end

  def monster_preview_section(assigns) do
    ~H"""
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
    """
  end

  # Helper function moved from DMLive
  defp all_players_ready?(assigns) do
    claimed_players = Map.keys(assigns.claimed_players)
    initiatives = Map.keys(assigns.player_initiatives)
    Enum.all?(claimed_players, &(&1 in initiatives))
  end
end