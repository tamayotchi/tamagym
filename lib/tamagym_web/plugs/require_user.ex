defmodule TamagymWeb.Plugs.RequireUser do
  import Phoenix.Controller
  import Plug.Conn

  def init(opts), do: opts

  def call(%{assigns: %{current_user: nil}} = conn, _opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "You need to sign in"})
    |> halt()
  end

  def call(conn, _opts), do: conn
end
