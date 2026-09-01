defmodule TamagymWeb.NotFoundController do
  use TamagymWeb, :controller

  def api(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "API endpoint not found"})
  end
end
