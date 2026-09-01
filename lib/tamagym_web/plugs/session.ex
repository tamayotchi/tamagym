defmodule TamagymWeb.Plugs.Session do
  @moduledoc false

  def options do
    [
      store: :cookie,
      key: "_tamagym_session",
      signing_salt: "A8NYZUlv",
      encryption_salt: "tA9g4m2dYqL8vP3n",
      same_site: "Lax",
      http_only: true,
      secure: Application.get_env(:tamagym, :secure_cookies, false),
      max_age: 60 * 24 * 60 * 60
    ]
  end

  def init(opts), do: opts

  def call(conn, _opts) do
    Plug.Session.call(conn, Plug.Session.init(options()))
  end
end
