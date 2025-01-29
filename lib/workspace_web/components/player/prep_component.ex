defmodule WorkspaceWeb.Player.PrepComponent do
  use Phoenix.Component
  import WorkspaceWeb.GameComponents

  def prep(assigns) do
    ~H"""
    <div id="device-id-manager" phx-hook="DeviceId"></div>
    <div class="min-h-screen bg-white sm:bg-gray-50">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-3 sm:px-4">
        <div class="max-w-4xl mx-auto">
          <h1 class="text-2xl sm:text-4xl font-bold text-gray-900 mb-4 sm:mb-8 mt-4 sm:mt-8">
            Choose Your Character
          </h1>
          <.character_selection_card {assigns} />
        </div>
      </div>
    </div>
    """
  end

  def character_selection_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm p-4 sm:p-6">
      <div class="space-y-3 sm:space-y-4">
        <%= for player <- @players do %>
          <.character_option
            player={player}
            claimed_players={@claimed_players}
            device_id={@device_id}
          />
        <% end %>
      </div>
      <%= if has_claimed_player?(@claimed_players, @device_id) do %>
        <div class="mt-6 sm:mt-8 text-center text-gray-600 text-sm sm:text-base">
          Waiting for other players and DM...
        </div>
      <% end %>
    </div>
    """
  end

  def character_option(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-3 sm:p-4 bg-gray-50 rounded-lg">
      <span class="font-medium text-gray-900 text-sm sm:text-base"><%= @player %></span>
      <%= if is_player_claimed?(@player, @claimed_players) do %>
        <%= if is_my_player?(@player, @claimed_players, @device_id) do %>
          <div class="text-green-600 font-medium text-sm sm:text-base">
            Your Character
          </div>
        <% else %>
          <div class="text-gray-500 text-sm sm:text-base">
            Already Claimed
          </div>
        <% end %>
      <% else %>
        <button 
          phx-click="claim_player"
          phx-value-player={@player}
          class="bg-indigo-600 hover:bg-indigo-700 text-white px-3 sm:px-4 py-1.5 sm:py-2 
                 rounded-md sm:rounded-lg transition-colors duration-200 text-sm sm:text-base
                 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
        >
          Choose Character
        </button>
      <% end %>
    </div>
    """
  end

  # Helper functions remain the same
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