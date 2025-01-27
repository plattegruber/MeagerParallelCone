defmodule WorkspaceWeb.HistoryPanelComponent do
  use Phoenix.Component
  
  def history_panel(assigns) do
    ~H"""
    <div class="bg-white shadow-lg rounded-lg p-4 overflow-y-auto
                lg:w-80 lg:fixed lg:right-4 lg:top-24 lg:bottom-4
                w-full mt-8 mx-4 lg:mx-0">
      <h2 class="text-xl font-semibold mb-4">Combat History</h2>
      <div class="space-y-2">
        <%= for entry <- Enum.reverse(@combat_history) do %>
          <div class="flex items-center justify-between p-2 rounded-md hover:bg-gray-50">
            <div class="flex-1">
              <p class="text-sm text-gray-700">
                <span class="font-medium"><%= entry.creature_name %></span>
                <%= if entry.type == :damage do %>
                  took <%= entry.amount %> damage
                <% else %>
                  healed <%= entry.amount %> HP
                <% end %>
              </p>
            </div>
            <%= if @is_dm do %>
              <button
                phx-click="delete_history_entry"
                phx-value-entry-id={entry.id}
                class="text-red-600 hover:text-red-700 text-sm ml-2"
              >
                Undo
              </button>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end