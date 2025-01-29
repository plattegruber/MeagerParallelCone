defmodule WorkspaceWeb.HistoryPanelComponent do
  use Phoenix.Component
  
  def history_panel(assigns) do
    ~H"""
      <div class={[
      "bg-white shadow-lg rounded-lg overflow-hidden",
      "lg:w-80 lg:fixed lg:right-4 lg:top-24 lg:bottom-4",
      "w-full mx-auto sm:mx-4 lg:mx-0", # Adjust margins
    ]}>
      <div class="sticky top-0 bg-white z-10 px-4 py-3 border-b">  <%!-- Adjusted padding --%>
        <h2 class="text-lg font-semibold">Combat History</h2>
      </div>
      
      <div class="px-4 py-3 space-y-2 overflow-y-auto max-h-[60vh] lg:max-h-[calc(100vh-11rem)]">
        <%= if Enum.empty?(@combat_history) do %>
          <p class="text-sm text-gray-500 text-center py-4">No combat history yet</p>
        <% else %>
          <%= for entry <- Enum.reverse(@combat_history) do %>
            <div class="group flex items-center justify-between p-2 rounded-md hover:bg-gray-50 transition-colors duration-150">
              <div class="flex-1 min-w-0"> <%!-- Add min-w-0 to allow truncation --%>
                <p class="text-sm text-gray-700 pr-2"> <%!-- Add right padding for spacing from button --%>
                  <span class="font-medium truncate inline-block align-bottom max-w-[140px]">
                    <%= entry.creature_name %>
                  </span>
                  <span class="whitespace-nowrap">
                    <%= case entry.type do %>
                      <% :damage -> %> took <%= entry.amount %> damage
                      <% :heal -> %> healed <%= entry.amount %> HP
                      <% :death -> %> died
                      <% :resurrection -> %> was resurrected
                    <% end %>
                  </span>
                </p>
              </div>
              <%= if @is_dm do %>
                <button
                  phx-click="delete_history_entry"
                  phx-value-entry-id={entry.id}
                  class="text-red-500 hover:text-red-700 text-sm px-2 py-1 rounded
                         opacity-0 group-hover:opacity-100 transition-opacity duration-150
                         focus:opacity-100 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-opacity-50"
                >
                  Undo
                </button>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end