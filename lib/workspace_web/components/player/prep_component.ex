# lib/workspace_web/components/player/prep_component.ex
defmodule WorkspaceWeb.Player.PrepComponent do
  use Phoenix.Component
  import WorkspaceWeb.GameComponents

  def prep(assigns) do
    ~H"""
    <div id="device-id-manager" phx-hook="DeviceId"></div>
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-4xl">
        <h1 class="text-4xl font-bold text-gray-900 mb-8">Choose Your Character</h1>
        <.character_selection_card {assigns} />
      </div>
    </div>
    """
  end

  def character_selection_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm p-6">
      <div class="space-y-4">
        <%= for player <- @players do %>
          <.character_option
            player={player}
            claimed_players={@claimed_players}
            device_id={@device_id}
          />
        <% end %>
      </div>

      <%= if has_claimed_player?(@claimed_players, @device_id) do %>
        <div class="mt-8 text-center text-gray-600">
          Waiting for other players and DM...
        </div>
      <% end %>
    </div>
    """
  end

  def character_option(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
      <span class="font-medium text-gray-900"><%= @player %></span>

      <%= if is_player_claimed?(@player, @claimed_players) do %>
        <%= if is_my_player?(@player, @claimed_players, @device_id) do %>
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
          phx-value-player={@player}
          class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition-colors duration-200"
        >
          Choose Character
        </button>
      <% end %>
    </div>
    """
  end

  # Helper functions
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