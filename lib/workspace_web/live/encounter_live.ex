defmodule EncounterTrackerWeb.EncounterLive do
  use EncounterTrackerWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      page: :setup,  # either :setup or :combat
      players: ["Gandalf", "Aragorn", "Legolas"],  # We can make this configurable later
      player_initiatives: %{},
      monsters: []
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <%= if @page == :setup do %>
        <h1 class="text-2xl font-bold mb-4">Setup Encounter</h1>

        <div class="mb-6">
          <h2 class="text-xl mb-2">Players</h2>
          <%= for player <- @players do %>
            <div class="mb-2">
              <label><%= player %>'s Initiative:</label>
              <input type="number" phx-change="set_player_initiative" value={Map.get(@player_initiatives, player)} phx-value-player={player} class="border p-1"/>
            </div>
          <% end %>
        </div>

        <div class="mb-6">
          <h2 class="text-xl mb-2">Add Monster</h2>
          <form phx-submit="add_monster">
            <input type="text" name="name" placeholder="Monster Name" class="border p-1 mr-2"/>
            <input type="number" name="hp" placeholder="HP" class="border p-1 mr-2"/>
            <input type="number" name="initiative_bonus" placeholder="Initiative Bonus" class="border p-1 mr-2"/>
            <button type="submit" class="bg-blue-500 text-white px-4 py-1 rounded">Add</button>
          </form>
        </div>

        <button phx-click="start_combat" class="bg-green-500 text-white px-4 py-2 rounded">Start Combat</button>
      <% else %>
        <h1>Combat View - Coming soon!</h1>
      <% end %>
    </div>
    """
  end

  def handle_event("set_player_initiative", %{"player" => player, "value" => value}, socket) do
    initiatives = Map.put(socket.assigns.player_initiatives, player, value)
    {:noreply, assign(socket, player_initiatives: initiatives)}
  end

  def handle_event("add_monster", params, socket) do
    monster = %{
      name: params["name"],
      hp: String.to_integer(params["hp"]),
      max_hp: String.to_integer(params["hp"]),
      initiative_bonus: String.to_integer(params["initiative_bonus"])
    }
    {:noreply, assign(socket, monsters: [monster | socket.assigns.monsters])}
  end

  def handle_event("start_combat", _params, socket) do
    # We'll implement this next
    {:noreply, assign(socket, page: :combat)}
  end
end