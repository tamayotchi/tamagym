defmodule TamagymWeb.GymLiveTest do
  use TamagymWeb.ConnCase

  alias Tamagym.Accounts
  alias Tamagym.Gym
  alias Tamagym.Gym.State

  test "registration form renders its confirmation password input", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/?auth=register")

    assert html =~ "Create account"
    assert has_element?(view, "#auth-form input[type='password']")
    assert has_element?(view, "input[name='confirmation'][type='password']")
  end

  test "offers local mode and opens the application without an account", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Continue without an account"

    home = view |> element("button", "Continue without an account") |> render_click()
    assert home =~ "Body weight"
    assert home =~ "Build my own plan"
    refute home =~ "week streak"
    refute has_element?(view, ".home-streak")
    assert has_element?(view, "#tabbar button.start", "Start")

    view |> element("button.today-row") |> render_click()
    assert has_element?(view, "#modal-root", "Pick what to train today.")
    assert has_element?(view, "#modal-root button", "Rest / skip this day")

    view |> element("button.sheet-close[phx-click='modal:close']") |> render_click()
    view |> element("#tabbar button[phx-value-to='/plan']") |> render_click()
    assert_patch(view, ~p"/plan")
    assert render(view) =~ "Weekly schedule"
    refute render(view) =~ "Sign in"
  end

  test "an authenticated user can create and persist a routine", %{conn: conn} do
    {:ok, user} = Accounts.register_user(%{email: "live@example.com", password: "long-password"})
    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, _html} = live(conn, ~p"/plan")

    view |> element("button", "New routine") |> render_click()
    path = assert_patch(view)

    [routine_id] =
      path |> URI.parse() |> Map.fetch!(:path) |> String.split("/", trim: true) |> Enum.drop(2)

    assert [%{"id" => ^routine_id, "name" => "New routine"}] = Gym.get_data(user)["routines"]
    assert has_element?(view, "button[phx-click='routine:delete']", "Delete")
    refute has_element?(view, "#routine-form button[type='submit']")

    view
    |> form("#routine-form", %{"name" => "Strength day", "emoji" => "dumbbell"})
    |> render_change()

    state = Gym.get_data(user)
    assert [%{"id" => ^routine_id, "name" => "Strength day"}] = state["routines"]

    {:ok, plan_view, plan_html} = live(conn, ~p"/plan")
    refute plan_html =~ "<select"

    plan_view |> element("button[phx-click='schedule:open'][phx-value-day='1']") |> render_click()
    assert has_element?(plan_view, "#modal-root", "Monday")
    assert has_element?(plan_view, "#modal-root button", "Rest day")

    plan_view
    |> element(
      "#modal-root button[phx-click='schedule:assign'][phx-value-routine='#{routine_id}']"
    )
    |> render_click()

    assert Gym.get_data(user)["week"]["1"] == routine_id

    assert has_element?(
             plan_view,
             "button[phx-click='schedule:open'][phx-value-day='1']",
             "Strength day"
           )

    {:ok, home_view, _html} = live(conn, ~p"/home")
    home_view |> element("button.today-row") |> render_click()
    assert has_element?(home_view, "#modal-root", "Pick what to train today.")

    home_view
    |> element("#modal-root button[phx-click='day:assign'][phx-value-routine='#{routine_id}']")
    |> render_click()

    assert Gym.get_data(user)["dayPlan"][Date.to_iso8601(Date.utc_today())] == routine_id
  end

  test "an authenticated user can generate, review, and apply an AI week", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "planner@example.com", password: "long-password"})

    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, _html} = live(conn, ~p"/plan")

    view |> element("button", "Plan my next 7 days") |> render_click()
    assert has_element?(view, "#modal-root", "Choose your goal")

    view
    |> form("form[phx-submit='ai:week-generate']", %{"goal" => "strength"})
    |> render_submit()

    assert has_element?(view, "#modal-root", "Generating your plan")
    assert render_async(view) =~ "Review your 7-day plan"
    assert has_element?(view, ".ai-week-preview .ai-day", "Generated session 1")
    assert has_element?(view, ".ai-week-preview .ai-day", "Rest")

    view |> element("button[phx-click='ai:week-apply']", "Apply plan") |> render_click()

    state = Gym.get_data(user)
    assert map_size(state["dayPlan"]) == 7
    assert map_size(state["week"]) == 3
    assert length(Enum.filter(state["routines"], &(&1["source"] == "ai"))) == 3
  end

  test "a user can generate a new AI routine for selected weekday muscle groups", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "day-planner@example.com", password: "long-password"})

    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, _html} = live(conn, ~p"/plan")

    view |> element("button[phx-click='schedule:open'][phx-value-day='1']") |> render_click()
    assert has_element?(view, "#modal-root", "Generate routine with AI")

    view
    |> element("button[phx-click='ai:day-open'][phx-value-day='1']")
    |> render_click()

    assert has_element?(view, "#modal-root", "Choose muscle groups")

    view
    |> element("button[phx-click='ai:day-muscle-toggle'][phx-value-group='back']")
    |> render_click()

    view
    |> element("button[phx-click='ai:day-muscle-toggle'][phx-value-group='shoulders']")
    |> render_click()

    view
    |> element("button[phx-click='ai:day-generate'][phx-value-day='1']")
    |> render_click()

    assert has_element?(view, "#modal-root", "Generating routine")
    assert render_async(view) =~ "Review AI routine"
    assert has_element?(view, ".ai-day-routine-exercises .item")
    assert has_element?(view, ".ai-technique-label", "Last set: Drop-set")

    view
    |> element("button[phx-click='ai:day-apply'][phx-value-day='1']", "Create and assign")
    |> render_click()

    state = Gym.get_data(user)
    assert [routine] = state["routines"]
    assert state["week"]["1"] == routine["id"]
    assert routine["muscleGroups"] == ["back", "shoulders"]
    assert length(routine["ex"]) == 6

    assert [[nil, nil, %{"type" => "dropset", "count" => 1, "pct" => 20}]] =
             routine["ex"]
             |> Enum.map(& &1["setTechniques"])
             |> Enum.reject(&is_nil/1)
  end

  test "a user can request and select an AI exercise alternative", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "alternatives@example.com", password: "long-password"})

    state =
      State.defaults()
      |> Map.put("active", %{
        "id" => "active-alternative",
        "d" => Date.to_iso8601(Date.utc_today()),
        "start" => System.system_time(:millisecond),
        "name" => "Core",
        "cur" => 0,
        "entries" => [
          %{
            "id" => "0001",
            "target" => %{"sets" => 3, "reps" => 10},
            "sets" => [%{"w" => 0, "r" => 10, "done" => false}]
          }
        ]
      })

    assert {:ok, :ok} = Gym.put_data(user, state)

    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, _html} = live(conn, ~p"/workout")

    refute has_element?(
             view,
             ".workout-exercise-actions button[phx-click='ai:alternatives-open']"
           )

    view |> element("button[phx-click='workout:swap-open']") |> render_click()

    assert has_element?(
             view,
             "#modal-root button[phx-click='ai:alternatives-open']",
             "Find alternatives with AI"
           )

    view |> element("#modal-root button[phx-click='ai:alternatives-open']") |> render_click()
    assert has_element?(view, "#modal-root", "Why can't you do this exercise?")

    view
    |> element("button[phx-click='ai:alternatives-generate'][phx-value-reason='equipment']")
    |> render_click()

    assert render_async(view) =~ "Choose an alternative"
    assert has_element?(view, "#modal-root .ai-alternatives button.item")

    view |> element("#modal-root .ai-alternatives button.item:first-child") |> render_click()

    replacement_id =
      user
      |> Gym.get_data()
      |> get_in(["active", "entries"])
      |> List.first()
      |> Map.fetch!("id")

    refute replacement_id == "0001"
  end

  test "a user can add an AI-suggested exercise to the active workout", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "suggestions@example.com", password: "long-password"})

    state =
      State.defaults()
      |> Map.put("active", %{
        "id" => "active-suggestions",
        "d" => Date.to_iso8601(Date.utc_today()),
        "start" => System.system_time(:millisecond),
        "name" => "Back + Biceps",
        "cur" => 0,
        "entries" => [
          %{
            "id" => "0007",
            "target" => %{"sets" => 3, "reps" => 10},
            "sets" => [%{"w" => 20, "r" => 10, "done" => false}]
          }
        ]
      })

    assert {:ok, :ok} = Gym.put_data(user, state)

    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, _html} = live(conn, ~p"/workout")

    view |> element("button[phx-click='workout:exercise-picker']") |> render_click()

    assert has_element?(
             view,
             "#modal-root button[phx-click='ai:suggestions-generate']",
             "Suggest with AI"
           )

    view |> element("#modal-root button[phx-click='ai:suggestions-generate']") |> render_click()

    assert render_async(view) =~ "Choose a suggested exercise"
    assert has_element?(view, "#modal-root .ai-suggestions button.item")

    view |> element("#modal-root .ai-suggestions button.item:first-child") |> render_click()

    entries = Gym.get_data(user)["active"]["entries"]
    assert length(entries) == 2
    assert entries |> Enum.map(& &1["id"]) |> Enum.uniq() |> length() == 2
  end

  test "a routine can become a completed workout", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "workout@example.com", password: "long-password"})

    conn = init_test_session(conn, user_id: user.id)
    {:ok, plan_view, _html} = live(conn, ~p"/plan")

    plan_view |> element("button", "New routine") |> render_click()
    routine_path = assert_patch(plan_view)
    {:ok, routine_view, _html} = live(conn, routine_path)

    routine_view |> element("button[phx-click='routine:exercise-picker']") |> render_click()
    assert has_element?(routine_view, "#modal-root", "Add exercise")

    routine_view
    |> element("#modal-root button[phx-click='routine:add-exercise'][phx-value-id='0001']")
    |> render_click()

    assert has_element?(routine_view, "#modal-root", "Changes save automatically")

    assert has_element?(
             routine_view,
             "#exercise-media-routine-config-0001 img[src='/gif/0001-2gPfomN.gif']"
           )

    refute has_element?(
             routine_view,
             "#routine-config-form input[name='weight'][data-numeric-input='decimal']"
           )

    assert has_element?(routine_view, ".routine-plan-row", "3 sets × 10 reps")
    assert has_element?(routine_view, ".routine-muscle-card", "What this session hits")
    assert has_element?(routine_view, ".routine-muscle-card .bodymap .bm-v")
    assert has_element?(routine_view, ".routine-muscle-card .mchip", "Abs")

    assert has_element?(routine_view, ".routine-set-technique", "Set 1")
    assert has_element?(routine_view, ".routine-set-technique", "Set 3")

    assert has_element?(
             routine_view,
             "button[phx-click='routine:set-technique'][phx-value-set='2'][phx-value-type='dropset']",
             "Drop-set"
           )

    refute has_element?(
             routine_view,
             "button[phx-click='routine:set-technique'][phx-value-type='restpause']"
           )

    routine_view
    |> element(
      "button[phx-click='routine:set-technique'][phx-value-set='2'][phx-value-type='dropset']"
    )
    |> render_click()

    assert has_element?(routine_view, ".routine-set-technique:nth-child(3)", "Weight drop (%)")

    assert has_element?(
             routine_view,
             "#routine-config-form input[name='weight'][data-numeric-input='decimal']"
           )

    assert has_element?(routine_view, ".routine-plan-row", "Set 3: Drop-set")

    assert [%{"ex" => [%{"setTechniques" => [nil, nil, %{"type" => "dropset"}]}]}] =
             Gym.get_data(user)["routines"]

    routine_view
    |> element(
      "button[phx-click='routine:set-technique'][phx-value-set='2'][phx-value-type='none']"
    )
    |> render_click()

    routine_view
    |> element(
      "button[phx-click='routine:step-exercise'][phx-value-field='sets'][phx-value-direction='up']"
    )
    |> render_click()

    assert [%{"ex" => [%{"sets" => 4}]}] = Gym.get_data(user)["routines"]

    routine_view
    |> element(
      "button[phx-click='routine:step-exercise'][phx-value-field='sets'][phx-value-direction='down']"
    )
    |> render_click()

    assert [%{"name" => "New routine", "ex" => [%{"id" => "0001", "sets" => 3}]}] =
             Gym.get_data(user)["routines"]

    {:ok, workout_view, _html} = live(conn, ~p"/workout")

    workout_view
    |> element("button[phx-click='workout:prepare']", "New routine")
    |> render_click()

    assert_patch(workout_view, ~p"/workout")
    refute has_element?(workout_view, "#modal-root", "Log body weight")

    {:ok, active_view, html} = live(conn, ~p"/workout")
    assert html =~ "3/4 sit-up"
    assert html =~ "/gif/0001-2gPfomN.gif"
    refute has_element?(active_view, "#set-0-0 input[name='w']")
    assert has_element?(active_view, "#set-0-0 .stp.r")
    assert has_element?(active_view, ".workout-sets > .workout-warmup-action + .sethead")
    assert has_element?(active_view, "button[phx-click='workout:swap-open']", "Swap exercise")

    refute has_element?(
             active_view,
             ".workout-exercise-actions button[phx-click='ai:alternatives-open']"
           )

    active_view |> element("button[phx-click='workout:swap-open']") |> render_click()
    assert has_element?(active_view, "#modal-root", "Swap exercise")

    assert has_element?(
             active_view,
             "#modal-root button[phx-click='ai:alternatives-open']",
             "Find alternatives with AI"
           )

    active_view
    |> form("#exercise-search", %{"query" => "alternate biceps curl"})
    |> render_change()

    active_view
    |> element("#modal-root button[phx-click='workout:swap-exercise'][phx-value-id='0023']")
    |> render_click()

    assert has_element?(active_view, "#set-0-0 input[name='w']")
    assert render(active_view) =~ "alternate biceps curl"
    assert has_element?(active_view, "button[phx-click='drop:add'][phx-value-set='0']", "+ Drop")

    active_view
    |> form("#set-0-0", %{"entry" => "0", "set" => "0", "w" => "012,5", "r" => "015"})
    |> render_change()

    Enum.each(0..2, fn set_index ->
      assert has_element?(active_view, "#set-0-#{set_index} input[name='w'][value='12.5']")
      assert has_element?(active_view, "#set-0-#{set_index} input[name='r'][value='15']")
    end)

    active_view |> element("button[phx-click='drop:add'][phx-value-set='0']") |> render_click()
    assert has_element?(active_view, ".drop-row", "Drop 1")

    assert has_element?(
             active_view,
             ".drop-row button[phx-click='drop:step'][phx-value-field='w']"
           )

    active_view |> element(".drop-row button[phx-click='drop:remove']") |> render_click()
    refute has_element?(active_view, ".drop-row")

    active_view |> element("button[phx-click='workout:swap-open']") |> render_click()

    active_view
    |> form("#exercise-search", %{"query" => "3/4 sit-up"})
    |> render_change()

    active_view
    |> element("#modal-root button[phx-click='workout:swap-exercise'][phx-value-id='0001']")
    |> render_click()

    refute has_element?(active_view, "#set-0-0 input[name='w']")
    refute has_element?(active_view, "button[phx-click='drop:add']")

    active_view
    |> element("#set-0-0 button[phx-click='set:step'][phx-value-direction='up']")
    |> render_click()

    assert has_element?(active_view, "#set-0-0 input[name='r'][value='16']")
    assert has_element?(active_view, "#set-0-2")
    refute has_element?(active_view, "#set-0-3")

    active_view
    |> element("button[phx-click='set:add-warmup']", "Add warm-up set")
    |> render_click()

    assert has_element?(active_view, ".setrow.warmup")
    assert render(active_view) =~ "Warm-up"
    active_view |> element("button.warm-remove[phx-click='set:remove']") |> render_click()
    refute has_element?(active_view, ".setrow.warmup")

    active_view |> element("button[phx-click='set:add']", "Add set") |> render_click()
    assert has_element?(active_view, "#set-0-3")
    active_view |> element("button[phx-click='set:remove']", "Remove set") |> render_click()
    refute has_element?(active_view, "#set-0-3")

    active_view
    |> form("#set-0-0", %{"entry" => "0", "set" => "0", "r" => "8"})
    |> render_change()

    active_view |> element("button[phx-click='set:toggle'][phx-value-set='0']") |> render_click()
    assert_push_event(active_view, "rest:start", %{seconds: 90})
    active_view |> element("button.workout-finish", "Finish workout") |> render_click()
    assert has_element?(active_view, "#modal-root", "unfinished sets")
    active_view |> element("#modal-root button[phx-click='workout:finish']") |> render_click()
    assert_patch(active_view, ~p"/history")
    refute has_element?(active_view, "#modal-root")

    state = Gym.get_data(user)
    assert state["active"] == nil
    assert state["bodyweight"] == []

    assert [
             %{
               "entries" => [%{"sets" => [%{"done" => true, "w" => unloaded, "r" => 8} | _]}]
             } = workout
           ] = state["workouts"]

    assert is_nil(workout["bw"])
    assert unloaded == 0.0

    {:ok, stats_view, stats_html} = live(conn, ~p"/stats")
    assert stats_html =~ "Progress &amp; history"
    assert stats_html =~ "Activity — last 12 months"
    assert stats_html =~ "Muscle balance"
    assert stats_html =~ "Exercise progress"
    assert stats_html =~ "Recent workouts"
    assert has_element?(stats_view, ".stats-tiles .tile", "Workouts")
    refute has_element?(stats_view, "#stats-weight-chart")
    assert has_element?(stats_view, "button[phx-click='stats:exercise-open']", "3/4 sit-up")

    stats_view |> element("button[phx-click='bodyweight:open']", "Log") |> render_click()

    stats_view
    |> form("form[phx-submit='bodyweight:save']", %{"weight" => "81.2"})
    |> render_submit()

    assert has_element?(stats_view, "#stats-weight-chart [data-chart-point][data-value='81.2']")
    assert [%{"w" => 81.2}] = Gym.get_data(user)["bodyweight"]

    stats_view |> element("button[phx-click='stats:exercise-open']") |> render_click()
    assert has_element?(stats_view, "#modal-root", "Exercise progress")
  end

  test "discarding a workout closes its confirmation sheet", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "discard@example.com", password: "long-password"})

    state =
      State.defaults()
      |> Map.put("active", %{
        "id" => "discard-active",
        "d" => Date.to_iso8601(Date.utc_today()),
        "start" => System.system_time(:millisecond),
        "name" => "Discard me",
        "cur" => 0,
        "entries" => []
      })

    assert {:ok, :ok} = Gym.put_data(user, state)
    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, _html} = live(conn, ~p"/workout")

    view |> element("button[phx-click='workout:cancel-open']") |> render_click()
    assert has_element?(view, "#modal-root", "Discard workout?")

    view |> element("#modal-root button[phx-click='workout:cancel']", "Discard") |> render_click()
    assert_patch(view, ~p"/home")
    refute has_element?(view, "#modal-root")
    assert Gym.get_data(user)["active"] == nil
  end

  test "home body weight uses goal-aware actions and an interactive chart", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "weight-ui@example.com", password: "long-password"})

    today = Date.utc_today()

    state =
      State.defaults()
      |> Map.put("targetW", 75.0)
      |> Map.put("bodyweight", [
        %{"d" => Date.to_iso8601(Date.add(today, -7)), "w" => 80.0},
        %{"d" => Date.to_iso8601(today), "w" => 79.0}
      ])

    assert {:ok, :ok} = Gym.put_data(user, state)
    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, html} = live(conn, ~p"/home")

    assert html =~ "Goal 75 kg · 4 kg to lose"
    assert has_element?(view, "button.home-goal.active", "75")
    assert has_element?(view, "button.home-log", "Log")
    assert has_element?(view, "#home-weight-chart polygon")
    assert has_element?(view, "#home-weight-chart .chart-hit-point[data-value='80']")
    assert has_element?(view, "#home-weight-chart .chart-hit-point[data-value='79']")
    assert has_element?(view, "#home-weight-chart .chart-selection[hidden]")
    assert has_element?(view, "#home-weight-chart text", "75")
  end

  test "exercise rows open an animated detail sheet", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "library@example.com", password: "long-password"})

    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, html} = live(conn, ~p"/library")

    assert html =~ "1324 exercises with animations"

    detail =
      view
      |> element("button[phx-click='exercise:open'][phx-value-id='0001']")
      |> render_click()

    assert detail =~ "/gif/0001-2gPfomN.gif"
    assert detail =~ "How to"
    assert detail =~ "Lie flat on your back"
  end

  test "English and Spanish are the only language choices", %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{email: "languages@example.com", password: "long-password"})

    conn = init_test_session(conn, user_id: user.id)
    {:ok, view, html} = live(conn, ~p"/settings")

    assert html =~ "General"
    refute html =~ "Phoenix LiveView"
    refute html =~ "Keep screen awake"
    refute html =~ "Sounds"

    view |> element("#language-preference") |> render_click()
    assert has_element?(view, "#modal-root", "English")
    assert has_element?(view, "#modal-root", "Spanish")
    refute render(view) =~ "French"

    spanish =
      view
      |> element("#modal-root button[phx-click='setting:set'][phx-value-setting='es']")
      |> render_click()

    assert spanish =~ "Ajustes"
    assert Gym.get_data(user)["lang"] == "es"

    view |> element("button[phx-click='ai:model-open']") |> render_click()

    view
    |> element("button[phx-click='ai:model-select'][phx-value-model='test:planner-b']")
    |> render_click()

    assert Gym.get_data(user)["aiModel"] == "test:planner-b"

    view
    |> element("button[phx-click='setting:set'][phx-value-key='unit'][phx-value-setting='lb']")
    |> render_click()

    view
    |> element(
      "button[phx-click='setting:set'][phx-value-key='theme'][phx-value-setting='light']"
    )
    |> render_click()

    view
    |> element("button[phx-click='setting:set'][phx-value-key='accent'][phx-value-setting='sky']")
    |> render_click()

    state = Gym.get_data(user)
    assert state["unit"] == "lb"
    assert state["theme"] == "light"
    assert state["accent"] == "sky"
    assert has_element?(view, "[phx-value-key='unit'][phx-value-setting='lb'].on")
    assert has_element?(view, "[phx-value-key='theme'][phx-value-setting='light'].on")
    assert has_element?(view, "[phx-value-key='accent'][phx-value-setting='sky'].on")
  end
end
