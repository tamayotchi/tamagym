defmodule TamagymWeb.UserAuth do
  @moduledoc "Loads the signed-in account into LiveView's current scope."

  import Plug.Conn, only: [get_session: 2]
  import Phoenix.Component, only: [assign: 3]

  alias Tamagym.Accounts

  def live_session(conn) do
    %{"user_id" => get_session(conn, :user_id)}
  end

  def on_mount(:current_scope, _params, session, socket) do
    user = session["user_id"] && Accounts.get_user(session["user_id"])

    {:cont,
     assign(socket, :current_scope, if(user, do: %{user: user, local_only?: false}, else: nil))}
  end
end
