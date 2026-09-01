defmodule TamagymWeb.Router do
  use TamagymWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug TamagymWeb.Plugs.FetchCurrentUser
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TamagymWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :require_user do
    plug TamagymWeb.Plugs.RequireUser
  end

  scope "/api", TamagymWeb do
    pipe_through :api

    get "/health", HealthController, :show
    get "/csrf", AuthController, :csrf
    get "/me", AuthController, :me
    post "/register", AuthController, :register
    post "/login", AuthController, :login
    post "/logout", AuthController, :logout
  end

  scope "/api", TamagymWeb do
    pipe_through [:api, :require_user]

    get "/data", DataController, :show
    put "/data", DataController, :update
  end

  scope "/api", TamagymWeb do
    pipe_through :api
    match :*, "/*path", NotFoundController, :api
  end

  scope "/", TamagymWeb do
    get "/img/:filename", MediaController, :image
    get "/gif/:filename", MediaController, :gif
  end

  scope "/", TamagymWeb do
    pipe_through :browser

    post "/session", SessionController, :create
    delete "/session", SessionController, :delete

    live_session :gym,
      session: {TamagymWeb.UserAuth, :live_session, []},
      on_mount: [{TamagymWeb.UserAuth, :current_scope}] do
      live "/", GymLive, :home
      live "/home", GymLive, :home
      live "/plan", GymLive, :plan
      live "/plan/r/:id", GymLive, :routine
      live "/workout", GymLive, :workout
      live "/stats", GymLive, :stats
      live "/history", GymLive, :history
      live "/library", GymLive, :library
      live "/settings", GymLive, :settings
    end
  end
end
