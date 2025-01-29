# lib/workspace_web/components/player/role_notification_component.ex
defmodule WorkspaceWeb.RoleNotificationComponent do
  use Phoenix.Component

  def notification(assigns) do
    ~H"""
    <div
      id="role-notification"
      class={[
        "fixed top-4 right-4 z-50",
        "transition-all duration-300 ease-in-out",
        @show && "translate-y-0 opacity-100",
        !@show && "translate-y-[-1rem] opacity-0 pointer-events-none"
      ]}
    >
      <div class={[
        "rounded-lg border-l-4 p-4 w-72 shadow-md",
        role_styles(@role)
      ]}>
        <p class="text-gray-700"><%= role_message(@role) %></p>
      </div>
    </div>
    """
  end

  defp role_styles(role) do
    case role do
      "active" -> "bg-green-100 border-green-500"
      "on-deck" -> "bg-yellow-100 border-yellow-500"
      "scribe" -> "bg-blue-100 border-blue-500"
      "standby" -> "bg-gray-100 border-gray-500"
      _ -> ""
    end
  end

  defp role_message(role) do
    case role do
      "active" -> "It's your turn to act!"
      "on-deck" -> "You're up next - start planning your turn!"
      "scribe" -> "Record what just happened during the last turn!"
      "standby" -> "Take a quick break - others are acting"
      _ -> ""
    end
  end
end