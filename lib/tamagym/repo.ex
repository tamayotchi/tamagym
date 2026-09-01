defmodule Tamagym.Repo do
  use Ecto.Repo,
    otp_app: :tamagym,
    adapter: Ecto.Adapters.SQLite3
end
