defmodule TamagymWeb.HealthController do
  use TamagymWeb, :controller

  alias Tamagym.Repo

  def show(conn, _params) do
    case Repo.query("SELECT 1") do
      {:ok, _result} ->
        json(conn, %{status: "ok"})

      {:error, _reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error"})
    end
  end
end
