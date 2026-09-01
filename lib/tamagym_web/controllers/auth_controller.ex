defmodule TamagymWeb.AuthController do
  use TamagymWeb, :controller

  alias Ecto.Changeset
  alias Tamagym.Accounts

  def csrf(conn, _params) do
    json(conn, %{csrf_token: Plug.CSRFProtection.get_csrf_token()})
  end

  def me(%{assigns: %{current_user: nil}} = conn, _params) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "You need to sign in"})
  end

  def me(conn, _params) do
    json(conn, %{user: Accounts.public_user(conn.assigns.current_user)})
  end

  def register(conn, %{"email" => email, "password" => password}) do
    case Accounts.register_user(%{email: email, password: password}) do
      {:ok, user} -> sign_in(conn, user, :created)
      {:error, %Changeset{} = changeset} -> validation_error(conn, changeset)
      {:error, _reason} -> server_error(conn)
    end
  end

  def register(conn, _params), do: missing_credentials(conn)

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        sign_in(conn, user, :ok)

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def login(conn, _params), do: missing_credentials(conn)

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> json(%{ok: true})
  end

  defp sign_in(conn, user, status) do
    conn
    |> configure_session(renew: true)
    |> put_session(:user_id, user.id)
    |> put_status(status)
    |> json(%{user: Accounts.public_user(user)})
  end

  defp validation_error(conn, changeset) do
    message =
      changeset
      |> Changeset.traverse_errors(fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
      |> Enum.sort_by(fn {field, _messages} -> field end)
      |> List.first()
      |> case do
        {field, [message | _]} -> "#{humanize(field)} #{message}"
        _ -> "Could not create account"
      end

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: message})
  end

  defp humanize(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp missing_credentials(conn) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Email and password are required"})
  end

  defp server_error(conn) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "Could not create account"})
  end
end
