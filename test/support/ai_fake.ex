defmodule Tamagym.AI.Fake do
  @moduledoc false

  @behaviour Tamagym.AI

  @impl true
  def generate_object(_model, _system_prompt, prompt, _schema, _opts) do
    context = prompt_context(prompt)

    case context["task"] do
      "seven_day_plan" -> {:ok, week(context)}
      "single_day_routine" -> {:ok, day_routine(context)}
      "exercise_alternatives" -> {:ok, alternatives(context)}
      _task -> {:error, :unknown_fake_task}
    end
  end

  defp week(context) do
    prescriptions =
      context["exercise_catalogue"]
      |> Enum.take(5)
      |> Enum.map(fn exercise ->
        %{
          "exercise_id" => exercise["id"],
          "sets" => 3,
          "reps" => 10,
          "weight" => 20,
          "rest_seconds" => 90,
          "note" => "Use controlled repetitions.",
          "last_set_technique" => "none",
          "drop_count" => 1,
          "drop_percentage" => 20,
          "rest_pause_extra_reps" => 5,
          "rest_pause_seconds" => 15
        }
      end)

    days =
      context["expected_dates"]
      |> Enum.with_index()
      |> Enum.map(fn {date, index} ->
        if index in [0, 2, 4] do
          %{
            "date" => date,
            "kind" => "workout",
            "name" => "Generated session #{index + 1}",
            "rationale" => "Balanced work with recovery around it.",
            "exercises" => prescriptions
          }
        else
          %{
            "date" => date,
            "kind" => "rest",
            "name" => "Rest",
            "rationale" => "Recover for the next session.",
            "exercises" => []
          }
        end
      end)

    %{"summary" => "Three training days with recovery between sessions.", "days" => days}
  end

  defp day_routine(context) do
    candidates = context["candidate_exercises"]

    group_exercises =
      context["selected_muscle_groups"]
      |> Enum.flat_map(fn group ->
        candidates
        |> Enum.filter(&(group in &1["matching_groups"]))
        |> Enum.take(2)
      end)
      |> Enum.uniq_by(& &1["id"])

    selected =
      (group_exercises ++ candidates)
      |> Enum.uniq_by(& &1["id"])
      |> Enum.take(context["required_exercise_count"])

    exercises =
      selected
      |> Enum.with_index()
      |> Enum.map(fn {exercise, index} ->
        %{
          "exercise_id" => exercise["id"],
          "sets" => 3,
          "reps" => 10,
          "weight" => 20,
          "rest_seconds" => 90,
          "note" => "Use controlled repetitions.",
          "last_set_technique" => if(index == length(selected) - 1, do: "dropset", else: "none"),
          "drop_count" => 1,
          "drop_percentage" => 20,
          "rest_pause_extra_reps" => 5,
          "rest_pause_seconds" => 15
        }
      end)

    %{
      "name" => Enum.join(context["selected_muscle_groups"], " + "),
      "rationale" => "A complete commercial-gym session for the selected muscle groups.",
      "exercises" => exercises
    }
  end

  defp alternatives(context) do
    alternatives =
      context["candidate_exercises"]
      |> Enum.take(3)
      |> Enum.map(fn exercise ->
        %{
          "exercise_id" => exercise["id"],
          "reason" => "Targets a similar area with a different setup."
        }
      end)

    %{"alternatives" => alternatives}
  end

  defp prompt_context(prompt) do
    prompt
    |> String.split("INPUT_JSON:\n", parts: 2)
    |> List.last()
    |> String.trim()
    |> Jason.decode!()
  end
end
