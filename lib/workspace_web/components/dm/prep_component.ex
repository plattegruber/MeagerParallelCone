# lib/workspace_web/components/dm/prep_component.ex
defmodule WorkspaceWeb.DM.PrepComponent do
  use Phoenix.Component
  import WorkspaceWeb.GameComponents

  def prep(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-8">
      <.phase_indicator {assigns} />
      <div class="container mx-auto px-4 max-w-6xl">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-4xl font-bold text-gray-900">DM Setup</h1>
          <button 
            phx-click="start_rolling" 
            type="button" 
            class="bg-green-600 hover:bg-green-700 text-white font-medium py-3 px-8 rounded-lg text-lg transition-colors duration-200 shadow-sm"
          >
            Start Rolling Phase
          </button>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="space-y-8">
            <.players_section players={@players} claimed_players={@claimed_players} />
            <.current_monsters_section monsters={@monsters} />
          </div>

          <div class="space-y-8">
            <.quick_add_monsters monster_bank={@monster_bank} />
            <.custom_monster_form />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def players_section(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm p-6">
      <h2 class="text-2xl font-semibold text-gray-800 mb-4">Players</h2>
      <div class="space-y-4">
        <%= for player <- @players do %>
          <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <span class="font-medium text-gray-900"><%= player %></span>
            <%= if Map.has_key?(@claimed_players, player) do %>
              <div class="flex items-center gap-3">
                <span class="text-sm text-green-600">Claimed</span>
                <button
                  type="button"
                  phx-click="unlink_player"
                  phx-value-player={player}
                  class="text-sm text-red-600 hover:text-red-700"
                >
                  Unlink
                </button>
              </div>
            <% else %>
              <span class="text-sm text-gray-500">Unclaimed</span>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def current_monsters_section(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm p-6">
      <h2 class="text-2xl font-semibold text-gray-800 mb-4">Current Monsters</h2>
      <%= if Enum.empty?(@monsters) do %>
        <p class="text-gray-500 italic">No monsters added yet</p>
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

  def quick_add_monsters(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm p-6">
      <h2 class="text-2xl font-semibold text-gray-800 mb-4">Quick Add Monsters</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <%= for monster <- @monster_bank do %>
          <button
            type="button"
            phx-click="add_monster_from_bank"
            phx-value-name={monster.name}
            phx-value-hp={monster.hp}
            phx-value-initiative_bonus={monster.initiative_bonus}
            class="flex flex-col p-4 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors duration-200"
          >
            <span class="text-lg font-semibold text-gray-900"><%= monster.name %></span>
            <div class="text-sm text-gray-600 mt-1">
              <span class="mr-3">HP: <%= monster.hp %></span>
              <span>Initiative: +<%= monster.initiative_bonus %></span>
            </div>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  def custom_monster_form(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm p-6">
      <h2 class="text-2xl font-semibold text-gray-800 mb-4">Add Custom Monster</h2>
      <form phx-submit="add_monster" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Monster Name</label>
          <input 
            type="text" 
            name="name" 
            required
            placeholder="e.g., Dragon" 
            class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
          />
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">HP</label>
            <input 
              type="number" 
              name="hp" 
              required
              placeholder="e.g., 45" 
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Initiative Bonus</label>
            <input 
              type="number" 
              name="initiative_bonus" 
              required
              placeholder="e.g., 2" 
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            />
          </div>
        </div>
        <button 
          type="submit" 
          class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-2 px-4 rounded-md transition-colors duration-200"
        >
          Add Monster
        </button>
      </form>
    </div>
    """
  end
end