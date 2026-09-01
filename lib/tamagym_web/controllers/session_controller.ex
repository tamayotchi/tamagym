defmodule TamagymWeb.SessionController do
  use TamagymWeb, :controller

  alias Tamagym.Accounts

  def create(conn, %{
        "mode" => "register",
        "confirmation" => confirmation,
        "user" => %{"password" => password}
      })
      when confirmation != password do
    auth_error(conn, "The passwords do not match.")
  end

  def create(conn, %{"mode" => "register", "user" => params}) do
    case Accounts.register_user(params) do
      {:ok, user} -> sign_in(conn, user, "Account created.")
      {:error, %Ecto.Changeset{} = changeset} -> auth_error(conn, changeset_message(changeset))
      {:error, _reason} -> auth_error(conn, "Could not create the account.")
    end
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} -> sign_in(conn, user, "Welcome back.")
      {:error, :invalid_credentials} -> auth_error(conn, "Invalid email or password.")
    end
  end

  def create(conn, _params), do: auth_error(conn, "Email and password are required.")

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  defp sign_in(conn, user, message) do
    conn
    |> configure_session(renew: true)
    |> put_session(:user_id, user.id)
    |> put_flash(:info, message)
    |> redirect(to: ~p"/home")
  end

  defp auth_error(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/?auth=login")
  end

  defp changeset_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, options} ->
      Enum.reduce(options, message, fn {key, value}, result ->
        String.replace(result, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.sort()
    |> List.first()
    |> case do
      {field, [message | _]} -> "#{field |> Atom.to_string() |> String.capitalize()} #{message}"
      _ -> "Could not create the account."
    end
  end
end
