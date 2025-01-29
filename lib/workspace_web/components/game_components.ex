defmodule WorkspaceWeb.GameComponents do
  use Phoenix.Component

  def phase_indicator(assigns) do
    ~H"""
    <div class="bg-white border-b">
      <div class="container mx-auto px-3 sm:px-4 py-3 sm:py-4">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-3 sm:space-y-0">
          <div class="flex items-center">
            <div class="flex items-center space-x-2 sm:space-x-4 overflow-x-auto pb-1 sm:pb-0">
              <%= for {phase, index} <- Enum.with_index([:prep, :rolling, :combat]) do %>
                <div class="flex items-center flex-shrink-0">
                  <div class={[
                    "flex items-center justify-center h-7 sm:h-8 px-3 sm:px-4 rounded-full font-medium text-sm sm:text-base transition-colors duration-200",
                    if(@phase == phase, do: "bg-indigo-100 text-indigo-700", else: "bg-gray-100 text-gray-500")
                  ]}>
                    <%= case phase do %>
                      <% :prep -> %> Preparation
                      <% :rolling -> %> Initiative
                      <% :combat -> %> Combat
                    <% end %>
                  </div>
                  <%= if index < 2 do %>
                    <div class={[
                      "h-0.5 w-4 sm:w-8 flex-shrink-0",
                      phase_line_color(@phase, phase)
                    ]}></div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
  
          <div class="flex items-center justify-end text-sm sm:text-base">
            <%= case @phase do %>
              <% :prep -> %>
                <%= if @is_dm do %>
                  <span class="text-gray-500 sm:mr-4">Add monsters and wait for players</span>
                <% else %>
                  <%= if has_claimed_player?(@claimed_players, @device_id) do %>
                    <span class="text-gray-500">Waiting for DM...</span>
                  <% else %>
                    <span class="text-gray-500">Choose your character</span>
                  <% end %>
                <% end %>
  
              <% :rolling -> %>
                <%= if @is_dm do %>
                  <span class={[
                    "flex items-center",
                    if(all_players_ready?(assigns), do: "text-green-600", else: "text-gray-500")
                  ]}>
                    <%= if all_players_ready?(assigns) do %>
                      Ready for combat
                    <% else %>
                      Waiting for rolls...
                    <% end %>
                  </span>
                <% else %>
                  <%= if has_submitted_initiative?(assigns) do %>
                    <span class="text-gray-500">Waiting for others...</span>
                  <% else %>
                    <span class="text-gray-500">Roll initiative</span>
                  <% end %>
                <% end %>
  
              <% :combat -> %>
                <%= if @is_dm do %>
                  <span class="text-gray-500">Round <%= @current_turn + 1 %></span>
                <% else %>
                  <%= if is_my_turn?(assigns) do %>
                    <span class="text-indigo-600 font-medium">Your turn!</span>
                  <% else %>
                    <span class="text-gray-500">
                      <%= current_player_name(assigns) %>'s turn
                    </span>
                  <% end %>
                <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions
  defp phase_line_color(current_phase, this_phase) do
    phases = [:prep, :rolling, :combat]
    current_index = Enum.find_index(phases, &(&1 == current_phase))
    this_index = Enum.find_index(phases, &(&1 == this_phase))

    cond do
      current_index > this_index -> "bg-indigo-500"  # Past phase
      current_index == this_index -> "bg-indigo-500" # Current phase
      true -> "bg-gray-200"  # Future phase
    end
  end

  defp has_submitted_initiative?(assigns) do
    my_player = get_my_player(assigns.claimed_players, assigns.device_id)
    my_player && Map.has_key?(assigns.player_initiatives, my_player)
  end

  defp is_my_turn?(assigns) do
    case Enum.at(assigns.combat_order, assigns.current_turn) do
      %{name: name} -> is_my_player?(name, assigns.claimed_players, assigns.device_id)
      _ -> false
    end
  end

  defp current_player_name(assigns) do
    case Enum.at(assigns.combat_order, assigns.current_turn) do
      %{name: name} -> name
      _ -> "Unknown"
    end
  end

  defp get_my_player(claimed_players, device_id) do
    claimed_players
    |> Enum.find(fn {_player, id} -> id == device_id end)
    |> case do
      {player, _} -> player
      nil -> nil
    end
  end

  defp has_claimed_player?(claimed_players, device_id) do
    Enum.any?(claimed_players, fn {_player, id} -> id == device_id end)
  end

  defp is_my_player?(player, claimed_players, device_id) do
    claimed_players[player] == device_id
  end

  defp all_players_ready?(assigns) do
    claimed_players = Map.keys(assigns.claimed_players)
    initiatives = Map.keys(assigns.player_initiatives)

    # All claimed players have submitted initiatives
    Enum.all?(claimed_players, &(&1 in initiatives))
  end
end