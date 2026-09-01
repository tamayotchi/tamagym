defmodule Tamagym.Gym.StateTest do
  use ExUnit.Case, async: true

  alias Tamagym.Gym.State

  test "warm-up sets are inserted before work and excluded from volume" do
    state = active_state(%{"w" => 40.0, "r" => 8, "done" => false})
    state = State.add_warmup_set(state, 0)

    [warmup, work] = state["active"]["entries"] |> List.first() |> Map.fetch!("sets")
    assert State.warmup_set?(warmup)
    assert warmup["w"] == 20.0
    assert warmup["r"] == 8
    refute State.warmup_set?(work)

    entry =
      state["active"]["entries"]
      |> List.first()
      |> Map.put("sets", [Map.put(warmup, "done", true), Map.put(work, "done", true)])

    workout = Map.put(state["active"], "entries", [entry])
    assert State.workout_volume(workout) == 320.0
  end

  test "drop sets keep independent weight and reps and add to volume" do
    state = active_state(%{"w" => 40.0, "r" => 10, "done" => false})
    state = State.add_drop(state, 0, 0)

    set = get_set(state)
    assert set["type"] == "dropset"
    assert [%{"w" => 32.0, "r" => 10}] = set["drops"]

    state = State.step_drop(state, 0, 0, 0, "w", 1)
    state = State.step_drop(state, 0, 0, 0, "r", 1)
    assert [%{"w" => 34.5, "r" => 11}] = get_set(state)["drops"]

    entry = state["active"]["entries"] |> List.first()
    [set] = entry["sets"]

    workout =
      Map.put(state["active"], "entries", [Map.put(entry, "sets", [Map.put(set, "done", true)])])

    assert State.workout_volume(workout) == 779.5

    state = State.remove_drop(state, 0, 0, 0)
    refute Map.has_key?(get_set(state), "drops")
    refute Map.has_key?(get_set(state), "type")
  end

  test "a planned drop set is built only on its selected set" do
    {state, routine_id} = State.add_routine(State.defaults(), "Drop day")
    state = State.add_routine_exercise(state, routine_id, "0023")

    state =
      State.configure_routine_exercise(state, routine_id, 0, %{
        "sets" => 2,
        "reps" => 10,
        "weight" => 50,
        "setTechniques" => [nil, %{"type" => "dropset", "count" => 2, "pct" => 20}]
      })
      |> State.start_workout(routine_id)

    [entry] = state["active"]["entries"]
    assert length(entry["sets"]) == 2

    [normal, drop_set] = entry["sets"]
    refute Map.has_key?(normal, "type")
    assert drop_set["type"] == "dropset"
    assert drop_set["drops"] == [%{"w" => 40.0, "r" => 10}, %{"w" => 32.0, "r" => 10}]
  end

  test "planned rest-pause adds bursts only to its selected set" do
    {state, routine_id} = State.add_routine(State.defaults(), "Rest-pause day")
    state = State.add_routine_exercise(state, routine_id, "0001")

    state =
      State.configure_routine_exercise(state, routine_id, 0, %{
        "sets" => 3,
        "reps" => 10,
        "setTechniques" => [
          nil,
          nil,
          %{"type" => "restpause", "totalReps" => 8, "restSec" => 15}
        ]
      })
      |> State.start_workout(routine_id)

    [first, second, rest_pause] =
      state["active"]["entries"] |> List.first() |> Map.fetch!("sets")

    refute Map.has_key?(first, "type")
    refute Map.has_key?(second, "type")
    assert rest_pause["type"] == "restpause"
    assert rest_pause["r"] == 18
    assert Enum.map(rest_pause["clusters"], & &1["r"]) == [4, 2, 1, 1]
    assert Enum.all?(rest_pause["clusters"], &(&1["restSec"] == 15))
  end

  test "bursts remain attached to their set and keep total reps in sync" do
    state = active_state(%{"w" => 30.0, "r" => 10, "done" => false})
    state = State.add_burst(state, 0, 0, 15)

    set = get_set(state)
    assert set["type"] == "restpause"
    assert set["r"] == 15
    assert [%{"r" => 5, "restSec" => 15}] = set["clusters"]

    state = State.step_burst(state, 0, 0, 0, 1)
    assert get_set(state)["r"] == 16
    assert [%{"r" => 6}] = Enum.map(get_set(state)["clusters"], &Map.take(&1, ["r"]))

    state = State.remove_burst(state, 0, 0, 0)
    set = get_set(state)
    assert set["r"] == 10
    refute Map.has_key?(set, "clusters")
    refute Map.has_key?(set, "type")
  end

  test "an AI week creates exact-date overrides and replaces the recurring weekly schedule" do
    start_date = ~D[2026-09-07]

    plan =
      ai_plan(start_date)
      |> update_in(["days"], fn days ->
        List.update_at(days, 0, fn day ->
          update_in(day["exercises"], fn [prescription] ->
            [
              Map.put(prescription, "last_set_technique", %{
                "type" => "restpause",
                "totalReps" => 5,
                "restSec" => 15
              })
            ]
          end)
        end)
      end)

    user_routine = %{
      "id" => "user-routine",
      "name" => "My original routine",
      "emoji" => "dumbbell",
      "ex" => []
    }

    initial_state =
      State.defaults()
      |> Map.put("routines", [user_routine])
      |> Map.put("week", Map.new(0..6, &{Integer.to_string(&1), user_routine["id"]}))

    state = State.apply_ai_week(initial_state, plan, start_date)

    assert map_size(state["dayPlan"]) == 7
    assert state["dayPlan"]["2026-09-08"] == "rest"
    assert length(state["routines"]) == 4
    assert user_routine in state["routines"]

    first = Enum.find(state["routines"], &(&1["plannedFor"] == "2026-09-07"))
    assert state["dayPlan"]["2026-09-07"] == first["id"]

    assert state["week"] == %{
             "1" => first["id"],
             "3" => state["dayPlan"]["2026-09-09"],
             "5" => state["dayPlan"]["2026-09-11"]
           }

    assert first["source"] == "ai"

    assert [%{"id" => "0001", "sets" => 3, "reps" => 10, "bodyweight" => true}] =
             Enum.map(first["ex"], &Map.take(&1, ["id", "sets", "reps", "bodyweight"]))

    assert [nil, nil, %{"type" => "restpause", "totalReps" => 5, "restSec" => 15}] =
             first["ex"] |> List.first() |> Map.fetch!("setTechniques")

    regenerated = State.apply_ai_week(state, plan, Date.add(start_date, 1))
    assert length(regenerated["routines"]) == 7
    assert user_routine in regenerated["routines"]

    previous_ids = MapSet.new(state["routines"], & &1["id"])
    regenerated_ids = MapSet.new(regenerated["routines"], & &1["id"])
    assert MapSet.subset?(previous_ids, regenerated_ids)
    refute regenerated["dayPlan"]["2026-09-07"] in previous_ids
  end

  test "an AI day creates and assigns a new routine without deleting existing routines" do
    existing = %{
      "id" => "existing",
      "name" => "Existing routine",
      "emoji" => "dumbbell",
      "ex" => []
    }

    draft =
      ai_plan(~D[2026-09-07])["days"]
      |> Enum.find(&(&1["kind"] == "workout"))
      |> Map.put("muscle_groups", ["back", "shoulders"])
      |> Map.update!("exercises", fn [prescription] ->
        [
          Map.merge(prescription, %{
            "exercise_id" => "0023",
            "weight" => 50,
            "last_set_technique" => %{"type" => "dropset", "count" => 2, "pct" => 20}
          })
        ]
      end)

    state =
      State.defaults()
      |> Map.put("routines", [existing])
      |> Map.put("week", %{"1" => existing["id"]})
      |> State.apply_ai_day("1", draft, ~D[2026-09-07])

    assert existing in state["routines"]
    assert length(state["routines"]) == 2

    generated = Enum.find(state["routines"], &(&1["id"] != existing["id"]))
    assert state["week"]["1"] == generated["id"]
    assert generated["source"] == "ai"
    assert generated["muscleGroups"] == ["back", "shoulders"]

    assert [nil, nil, %{"type" => "dropset", "count" => 2, "pct" => 20}] =
             generated["ex"] |> List.first() |> Map.fetch!("setTechniques")

    started = State.start_workout(state, generated["id"])
    [first, second, last] = started["active"]["entries"] |> List.first() |> Map.fetch!("sets")
    refute Map.has_key?(first, "type")
    refute Map.has_key?(second, "type")
    assert last["type"] == "dropset"
    assert length(last["drops"]) == 2
  end

  defp ai_plan(start_date) do
    days =
      Enum.map(0..6, fn offset ->
        date = Date.add(start_date, offset) |> Date.to_iso8601()

        if offset in [0, 2, 4] do
          %{
            "date" => date,
            "kind" => "workout",
            "name" => "Session",
            "rationale" => "Train",
            "exercises" => [
              %{
                "exercise_id" => "0001",
                "sets" => 3,
                "reps" => 10,
                "weight" => 0,
                "rest_seconds" => 90,
                "note" => ""
              }
            ]
          }
        else
          %{
            "date" => date,
            "kind" => "rest",
            "name" => "Rest",
            "rationale" => "Recover",
            "exercises" => []
          }
        end
      end)

    %{"summary" => "A balanced week", "days" => days}
  end

  defp active_state(set) do
    State.defaults()
    |> Map.put("active", %{
      "id" => "active",
      "cur" => 0,
      "entries" => [%{"id" => "0023", "target" => %{}, "sets" => [set]}]
    })
  end

  defp get_set(state) do
    state["active"]["entries"] |> List.first() |> Map.fetch!("sets") |> List.first()
  end
end
