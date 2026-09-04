defmodule Tamagym.Gym.AIPlannerTest do
  use ExUnit.Case, async: true

  alias Tamagym.Gym.{AIPlanner, Catalogue, State}

  test "generates and validates seven consecutive days beginning on the requested date" do
    state =
      State.defaults()
      |> Map.put("workouts", [
        %{
          "id" => "previous",
          "d" => "2026-09-05",
          "name" => "Core",
          "entries" => [
            %{
              "id" => "0001",
              "sets" => [%{"w" => 0, "r" => 10, "done" => true}]
            }
          ]
        }
      ])

    assert {:ok, plan} =
             AIPlanner.generate_week(state, "general_fitness", "test:planner-a", ~D[2026-09-07])

    assert Enum.map(plan["days"], & &1["date"]) ==
             Enum.map(0..6, &(Date.add(~D[2026-09-07], &1) |> Date.to_iso8601()))

    assert Enum.count(plan["days"], &(&1["kind"] == "workout")) == 3
    assert Enum.count(plan["days"], &(&1["kind"] == "rest")) == 4

    first_exercise =
      plan["days"]
      |> Enum.find(&(&1["kind"] == "workout"))
      |> Map.fetch!("exercises")
      |> List.first()

    assert first_exercise["exercise_id"] == "0001"
    assert first_exercise["weight"] == 0.0

    assert Enum.all?(
             Enum.filter(plan["days"], &(&1["kind"] == "workout")),
             &(length(&1["exercises"]) >= 4)
           )
  end

  test "generates a complete commercial-gym routine for selected muscle groups" do
    assert {:ok, routine} =
             AIPlanner.generate_day(
               State.defaults(),
               ["back", "shoulders"],
               "1",
               "test:planner-a"
             )

    assert routine["muscle_groups"] == ["back", "shoulders"]
    assert length(routine["exercises"]) == 6

    assert [%{"type" => "dropset", "count" => 1, "pct" => 20}] =
             routine["exercises"]
             |> Enum.map(& &1["last_set_technique"])
             |> Enum.reject(&is_nil/1)

    refute Enum.any?(routine["exercises"], fn prescription ->
             Catalogue.get(prescription["exercise_id"])["eq"] in [
               "body weight",
               "band",
               "resistance band",
               "stability ball"
             ]
           end)
  end

  test "suggests catalogue-backed exercises that are not already in the active workout" do
    state =
      State.defaults()
      |> Map.put("active", %{
        "id" => "active",
        "name" => "Back + Biceps",
        "entries" => [
          %{
            "id" => "0007",
            "target" => %{"sets" => 3, "reps" => 10},
            "sets" => [%{"w" => 20, "r" => 10, "done" => false}]
          }
        ]
      })

    assert {:ok, suggestions} = AIPlanner.suggestions(state, "test:planner-a")

    assert length(suggestions) == 3
    assert Enum.all?(suggestions, &is_binary(&1["reason"]))
    refute Enum.any?(suggestions, &(&1["exercise_id"] == "0007"))
  end

  test "returns catalogue-backed alternatives for the active exercise" do
    state =
      State.defaults()
      |> Map.put("active", %{
        "id" => "active",
        "entries" => [
          %{
            "id" => "0001",
            "target" => %{"sets" => 3, "reps" => 10},
            "sets" => [%{"w" => 0, "r" => 10, "done" => false}]
          },
          %{
            "id" => "0002",
            "target" => %{"sets" => 3, "reps" => 10},
            "sets" => [%{"w" => 0, "r" => 10, "done" => false}]
          }
        ]
      })

    assert {:ok, alternatives} =
             AIPlanner.alternatives(state, 0, "equipment", "test:planner-a")

    assert length(alternatives) == 3
    assert Enum.all?(alternatives, &is_binary(&1["exercise_id"]))
    refute Enum.any?(alternatives, &(&1["exercise_id"] in ["0001", "0002"]))
  end
end
