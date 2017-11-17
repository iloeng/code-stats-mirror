defmodule CodeStatsWeb.Router do
  use CodeStatsWeb, :router

  pipeline :browser_common do
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:put_secure_browser_headers)
    plug(CodeStatsWeb.RememberMePlug)
    plug(CodeStatsWeb.SetSessionUserPlug)
  end

  pipeline :browser_html do
    plug(:accepts, ["html"])
  end

  pipeline :browser_csv do
    plug(:accepts, ["csv"])
  end

  pipeline :browser_auth do
    plug(CodeStatsWeb.AuthRequiredPlug)
  end

  pipeline :browser_unauth do
    plug(CodeStatsWeb.AuthNotAllowedPlug)
  end

  pipeline :browser_changes_state do
    plug(:protect_from_forgery)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :api_machine_auth do
    plug(CodeStatsWeb.MachineAuthRequiredPlug)
  end

  scope "/" do
    pipe_through(:browser_html)
    pipe_through(:browser_common)

    get("/", CodeStatsWeb.PageController, :index)

    get("/api-docs", CodeStatsWeb.PageController, :api_docs)
    get("/tos", CodeStatsWeb.PageController, :terms)
    get("/plugins", CodeStatsWeb.PageController, :plugins)
    get("/changes", CodeStatsWeb.PageController, :changes)

    get("/aliases", CodeStatsWeb.AliasController, :list)

    get("/battle", CodeStatsWeb.BattleController, :battle)

    scope "/" do
      pipe_through(:browser_changes_state)
      pipe_through(:browser_unauth)

      get("/login", CodeStatsWeb.AuthController, :render_login)
      post("/login", CodeStatsWeb.AuthController, :login)
      get "/login/oauth/:app", AuthController, :oauth
      get("/signup", CodeStatsWeb.AuthController, :render_signup)
      post("/signup", CodeStatsWeb.AuthController, :signup)
      get("/forgot-password", CodeStatsWeb.AuthController, :render_forgot)
      post("/forgot-password", CodeStatsWeb.AuthController, :forgot)
      get("/reset-password/:token", CodeStatsWeb.AuthController, :render_reset)
      put("/reset-password/:token", CodeStatsWeb.AuthController, :reset)
    end

    get("/logout", CodeStatsWeb.AuthController, :logout)

    get("/users/:username", CodeStatsWeb.ProfileController, :profile)
    forward("/profile-graph", Absinthe.Plug, schema: CodeStats.Profile.PublicSchema)
    forward("/profile-graphiql", Absinthe.Plug.GraphiQL, schema: CodeStats.Profile.PublicSchema)

    scope "/my", CodeStatsWeb do
      pipe_through(:browser_changes_state)
      pipe_through(:browser_auth)

      get("/profile", ProfileController, :my_profile)

      get("/preferences", PreferencesController, :edit)
      put("/preferences", PreferencesController, :do_edit)

      post("/password", PreferencesController, :change_password)
      post("/sound_of_inevitability", PreferencesController, :delete)

      get("/machines", MachineController, :list)
      post("/machines", MachineController, :add)
      get("/machines/:id", MachineController, :view_single)
      put("/machines/:id", MachineController, :edit)
      delete("/machines/:id", MachineController, :delete)
      post("/machines/:id/activate", MachineController, :activate)
      post("/machines/:id/deactivate", MachineController, :deactivate)
      post("/machines/:id/key", MachineController, :regen_machine_key)
    end
  end

  scope "/", CodeStatsWeb do
    pipe_through(:browser_csv)
    pipe_through(:browser_common)
    pipe_through(:browser_auth)

    get("/my/pulses", PulseController, :list)
  end

  scope "/api", CodeStatsWeb do
    pipe_through(:api)

    get("/users/:username", ProfileController, :profile_api)

    scope "/my" do
      pipe_through(:api_machine_auth)

      post("/pulses", PulseController, :add)
    end
  end
end
