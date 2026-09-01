defmodule TamagymWeb.AuthAndDataControllerTest do
  use TamagymWeb.ConnCase, async: false

  import Ecto.Query

  alias Tamagym.Accounts.User

  alias Tamagym.Gym.{
    BodyWeight,
    CustomExercise,
    DayOverride,
    Routine,
    UserSettings,
    Workout
  }

  alias Tamagym.Repo

  describe "email/password authentication" do
    test "a new account starts with empty gym data", %{conn: conn} do
      {conn, token} = csrf(conn)

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> post("/api/register", %{email: "  ATHLETE@Example.com ", password: "strong-pass-123"})

      assert %{"user" => %{"email" => "athlete@example.com", "name" => "athlete"}} =
               json_response(conn, 201)

      user = Repo.get_by!(User, email: "athlete@example.com")
      refute user.password_hash == "strong-pass-123"
      assert Bcrypt.verify_pass("strong-pass-123", user.password_hash)

      conn = conn |> recycle() |> get("/api/data")

      assert %{
               "state" => %{
                 "routines" => [],
                 "week" => %{},
                 "dayPlan" => %{},
                 "workouts" => [],
                 "active" => nil,
                 "bodyweight" => [],
                 "customEx" => []
               }
             } = json_response(conn, 200)
    end

    test "validates registration and treats email addresses case-insensitively", %{conn: conn} do
      {conn, token} = csrf(conn)

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> post("/api/register", %{email: "person@example.com", password: "password-one"})

      assert response(conn, 201)

      {conn, token} = csrf(build_conn())

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> post("/api/register", %{email: "PERSON@example.com", password: "password-two"})

      assert %{"error" => error} = json_response(conn, 422)
      assert error =~ "Email has already been taken"
    end

    test "logs in, exposes the current account, and logs out", %{conn: conn} do
      registered = register(conn, "lifter@example.com", "correct-horse")
      logout_token = csrf_token(registered)

      conn =
        registered
        |> recycle()
        |> with_csrf(logout_token)
        |> post("/api/logout", %{})

      assert %{"ok" => true} = json_response(conn, 200)
      assert conn |> recycle() |> get("/api/me") |> json_response(401)

      {conn, token} = csrf(conn |> recycle())

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> post("/api/login", %{email: "LIFTER@example.com", password: "correct-horse"})

      assert %{"user" => %{"email" => "lifter@example.com"}} = json_response(conn, 200)

      assert %{"user" => %{"email" => "lifter@example.com"}} =
               conn |> recycle() |> get("/api/me") |> json_response(200)
    end

    test "rejects an incorrect password without revealing which credential failed", %{conn: conn} do
      _registered = register(conn, "known@example.com", "correct-horse")
      {conn, token} = csrf(build_conn())

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> post("/api/login", %{email: "known@example.com", password: "wrong-password"})

      assert %{"error" => "Invalid email or password"} = json_response(conn, 401)
    end
  end

  describe "per-user gym data" do
    test "requires authentication", %{conn: conn} do
      assert conn |> get("/api/data") |> json_response(401)
    end

    test "decomposes state into relational rows and reconstructs it", %{conn: conn} do
      conn = register(conn, "state@example.com", "state-password")
      user = Repo.get_by!(User, email: "state@example.com")
      token = csrf_token(conn)

      state = full_state()

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> put("/api/data", %{state: state})

      assert %{"ok" => true} = json_response(conn, 200)
      assert json_response(conn |> recycle() |> get("/api/data"), 200)["state"] == state

      assert count(Routine, user.id) == 1
      assert Repo.get_by!(Routine, user_id: user.id).data["ex"] |> length() == 2
      assert count(DayOverride, user.id) == 2
      assert count(Workout, user.id) == 2

      completed = Repo.get_by!(Workout, user_id: user.id, status: "completed")
      assert completed.data["entries"] |> length() == 1
      assert completed.data["entries"] |> hd() |> Map.fetch!("sets") |> length() == 2

      assert count(BodyWeight, user.id) == 1
      assert count(CustomExercise, user.id) == 1

      settings = Repo.get_by!(UserSettings, user_id: user.id)
      assert settings.data["theme"] == "dark"
      assert settings.data["week"] == %{"1" => "push"}
      refute Map.has_key?(settings.data, "routines")
      refute Map.has_key?(settings.data, "workouts")

      routine_id = Repo.get_by!(Routine, user_id: user.id).id
      completed_id = Repo.get_by!(Workout, user_id: user.id, status: "completed").id
      body_weight_id = Repo.get_by!(BodyWeight, user_id: user.id).id
      updated_state = put_in(state, ["active", "cur"], 1)
      token = csrf_token(conn)

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> put("/api/data", %{state: updated_state})

      assert %{"ok" => true} = json_response(conn, 200)
      assert Repo.get_by!(Routine, user_id: user.id).id == routine_id
      assert Repo.get_by!(Workout, user_id: user.id, status: "completed").id == completed_id
      assert Repo.get_by!(BodyWeight, user_id: user.id).id == body_weight_id
      assert Repo.get_by!(Workout, user_id: user.id, status: "active").data["cur"] == 1

      next_state = %{"routines" => [], "theme" => "light"}
      token = csrf_token(conn)

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> put("/api/data", %{state: next_state})

      assert %{"ok" => true} = json_response(conn, 200)
      assert count(Routine, user.id) == 0
      assert count(Workout, user.id) == 0
      assert count(BodyWeight, user.id) == 0
      assert Repo.get_by!(UserSettings, user_id: user.id).data == %{"theme" => "light"}

      assert %{
               "theme" => "light",
               "routines" => [],
               "workouts" => [],
               "active" => nil
             } = json_response(conn |> recycle() |> get("/api/data"), 200)["state"]
    end

    test "rejects invalid relationships without partially replacing prior data", %{conn: conn} do
      conn = register(conn, "transaction@example.com", "transaction-password")
      token = csrf_token(conn)

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> put("/api/data", %{
          state: %{routines: [%{id: "valid", name: "Valid", ex: []}], week: %{1 => "valid"}}
        })

      assert %{"ok" => true} = json_response(conn, 200)
      token = csrf_token(conn)

      conn =
        conn
        |> recycle()
        |> with_csrf(token)
        |> put("/api/data", %{
          state: %{
            routines: [%{id: "replacement", name: "Replacement", ex: []}],
            week: %{1 => "missing"}
          }
        })

      assert %{"error" => "Could not save gym data"} = json_response(conn, 422)
      assert Repo.aggregate(Routine, :count) == 1

      assert %{"routines" => [%{"id" => "valid"}], "week" => %{"1" => "valid"}} =
               json_response(conn |> recycle() |> get("/api/data"), 200)["state"]
    end

    test "keeps accounts isolated", %{conn: conn} do
      first = register(conn, "first@example.com", "first-password")
      token = csrf_token(first)

      first =
        first
        |> recycle()
        |> with_csrf(token)
        |> put("/api/data", %{state: %{routines: [%{id: "private"}]}})

      second = register(build_conn(), "second@example.com", "second-password")
      assert %{"state" => %{}} = second |> recycle() |> get("/api/data") |> json_response(200)

      assert %{"state" => %{"routines" => [%{"id" => "private"}]}} =
               first |> recycle() |> get("/api/data") |> json_response(200)
    end
  end

  defp full_state do
    %{
      "unit" => "kg",
      "theme" => "dark",
      "accent" => "lime",
      "equipProfiles" => [%{"id" => "home", "name" => "Home", "equipment" => ["dumbbell"]}],
      "routines" => [
        %{
          "id" => "push",
          "name" => "Push",
          "emoji" => "dumbbell",
          "prog" => "linear",
          "ex" => [
            %{"id" => "0025", "sets" => 3, "reps" => 8, "weight" => 60},
            %{"id" => "0026", "sets" => 3, "reps" => 10, "weight" => 20, "sg" => "pair"}
          ]
        }
      ],
      "week" => %{"1" => "push"},
      "dayPlan" => %{"2026-09-01" => "rest", "2026-09-02" => "push"},
      "workouts" => [
        %{
          "id" => "workout-1",
          "d" => "2026-08-30",
          "start" => 1_700_000_000_000,
          "end" => 1_700_000_003_600,
          "routineId" => "push",
          "name" => "Push",
          "bw" => 80.5,
          "vol" => 1_200.0,
          "prs" => ["0025"],
          "note" => "Strong session",
          "entries" => [
            %{
              "id" => "0025",
              "topW" => 80.0,
              "note" => "Pause each rep",
              "target" => %{"sets" => 2, "reps" => 5},
              "sets" => [
                %{
                  "w" => 80.0,
                  "r" => 5,
                  "done" => true,
                  "phase" => "work",
                  "rir" => 2.0,
                  "drops" => [%{"w" => 60, "r" => 8}]
                },
                %{"w" => 82.5, "r" => 4, "done" => true, "type" => "straight"}
              ]
            }
          ]
        }
      ],
      "active" => %{
        "id" => "active-1",
        "d" => "2026-08-31",
        "start" => 1_700_100_000_000,
        "routineId" => "push",
        "name" => "Push",
        "cur" => 0,
        "entries" => [
          %{
            "id" => "0026",
            "target" => %{"sets" => 1, "reps" => 10},
            "sets" => [%{"w" => 20.0, "r" => 10, "done" => false}]
          }
        ]
      },
      "bodyweight" => [%{"d" => "2026-08-30", "w" => 80.5, "t" => 1_700_000_000_000}],
      "customEx" => [
        %{"id" => "custom-1", "n" => "My press", "bp" => "chest", "custom" => true}
      ]
    }
  end

  defp count(schema, user_id) do
    schema
    |> where([row], row.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  defp register(conn, email, password) do
    {conn, token} = csrf(conn)

    conn
    |> recycle()
    |> with_csrf(token)
    |> post("/api/register", %{email: email, password: password})
  end

  defp csrf(conn) do
    conn = get(conn, "/api/csrf")
    {conn, json_response(conn, 200)["csrf_token"]}
  end

  defp csrf_token(conn) do
    {_, token} = csrf(conn |> recycle())
    token
  end

  defp with_csrf(conn, token), do: put_req_header(conn, "x-csrf-token", token)
end
