defmodule WorkspaceWeb.Player.RollingComponent do
 use Phoenix.Component
 import WorkspaceWeb.GameComponents

 def rolling(assigns) do
   ~H"""
   <div class="min-h-screen bg-white sm:bg-gray-50">
     <.phase_indicator {assigns} />
     <div class="container mx-auto px-3 sm:px-4">
       <div class="max-w-4xl mx-auto">
         <h1 class="text-2xl sm:text-4xl font-bold text-gray-900 mb-4 sm:mb-8 mt-4 sm:mt-8">
           Roll Initiative
         </h1>
         <.initiative_section {assigns} />
       </div>
     </div>
   </div>
   """
 end

 def initiative_section(assigns) do
   ~H"""
   <div class="bg-white rounded-lg shadow-sm p-4 sm:p-6">
     <%= if has_claimed_player?(@claimed_players, @device_id) do %>
       <div class="space-y-3 sm:space-y-4">
         <%= for player <- @players do %>
           <.player_initiative_row
             player={player}
             claimed_players={@claimed_players}
             device_id={@device_id}
             player_initiatives={@player_initiatives}
           />
         <% end %>
         <%= if Map.has_key?(@player_initiatives, get_my_player(@claimed_players, @device_id)) do %>
           <div class="mt-6 sm:mt-8 text-center text-gray-600 text-sm sm:text-base">
             Waiting for other players...
           </div>
         <% end %>
       </div>
     <% else %>
       <.unclaimed_player_message />
     <% end %>
   </div>
   """
 end

 def player_initiative_row(assigns) do
   ~H"""
   <div class="flex flex-col sm:flex-row sm:items-center justify-between p-3 sm:p-4 bg-gray-50 rounded-lg space-y-2 sm:space-y-0">
     <span class="font-medium text-gray-900 text-sm sm:text-base"><%= @player %></span>
     <%= if is_my_player?(@player, @claimed_players, @device_id) do %>
       <%= if Map.has_key?(@player_initiatives, @player) do %>
         <div class="text-green-600 font-medium text-sm sm:text-base">
           Initiative: <%= @player_initiatives[@player] %>
         </div>
       <% else %>
         <.initiative_form player={@player} />
       <% end %>
     <% else %>
       <%= if Map.has_key?(@player_initiatives, @player) do %>
         <div class="text-green-600 text-sm sm:text-base">Ready</div>
       <% else %>
         <div class="text-gray-500 text-sm sm:text-base">Waiting...</div>
       <% end %>
     <% end %>
   </div>
   """
 end

 def initiative_form(assigns) do
   ~H"""
   <form phx-submit="submit_initiative" class="flex items-center gap-2 w-full sm:w-auto">
     <input
       type="number"
       name="initiative"
       placeholder="Enter roll"
       required
       inputmode="numeric"
       pattern="[0-9]*"
       class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 
              text-base py-1.5 px-2 w-full sm:w-auto"
     />
     <input type="hidden" name="player" value={@player} />
     <button 
       type="submit"
       class="bg-indigo-600 hover:bg-indigo-700 text-white px-3 sm:px-4 py-1.5 sm:py-2 
              rounded-md sm:rounded-lg transition-colors duration-200 text-sm sm:text-base whitespace-nowrap
              focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
     >
       Submit
     </button>
   </form>
   """
 end

 def unclaimed_player_message(assigns) do
   ~H"""
   <div class="text-center py-6 sm:py-8">
     <p class="text-gray-600 mb-4 text-sm sm:text-base">You haven't chosen a character yet.</p>
     <a href="/" class="text-indigo-600 hover:text-indigo-800 font-medium text-sm sm:text-base">
       Go back to character selection
     </a>
   </div>
   """
 end

 # Helper functions remain the same
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
end