defmodule TamagymWeb.DataController do
  use TamagymWeb, :controller

  alias Tamagym.Gym

  @max_state_bytes 8_000_000

  def show(conn, _params) do
    json(conn, %{state: Gym.get_data(conn.assigns.current_user)})
  end

  def update(conn, %{"state" => state}) when is_map(state) do
    if encoded_size(state) > @max_state_bytes do
      conn
      |> put_status(:request_entity_too_large)
      |> json(%{error: "Gym data is too large"})
    else
      case Gym.put_data(conn.assigns.current_user, state) do
        {:ok, :ok} ->
          json(conn, %{ok: true})

        {:error, _changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "Could not save gym data"})
      end
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "State must be a JSON object"})
  end

  defp encoded_size(state) do
    state
    |> Jason.encode_to_iodata!()
    |> IO.iodata_length()
  end
end
