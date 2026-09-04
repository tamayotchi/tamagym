defmodule Tamagym.Gym.State do
  @moduledoc "Pure transformations for the LiveView gym state document."

  alias Tamagym.Gym.Catalogue

  @defaults %{
    "unit" => "kg",
    "restSec" => 90,
    "lang" => "en",
    "theme" => "dark",
    "accent" => "lime",
    "body" => "male",
    "targetW" => nil,
    "bodyweight" => [],
    "routines" => [],
    "week" => %{},
    "sports" => [],
    "dayPlan" => %{},
    "workouts" => [],
    "active" => nil,
    "customEx" => [],
    "equipProfiles" => [],
    "activeEquipId" => nil,
    "equipFilterOn" => false,
    "aiModel" => nil
  }

  def defaults, do: @defaults

  def clean(value) when is_map(value) do
    @defaults
    |> Map.merge(Map.delete(value, "restPauseSec"))
    |> normalize_sports()
    |> strip_rest_pause_data()
  end

  def clean(_value), do: @defaults

  def locale(state), do: if(state["lang"] == "es", do: "es", else: "en")

  def add_routine(state, name) do
    routine = %{
      "id" => uid("routine"),
      "name" => present(name, "New routine"),
      "emoji" => "dumbbell",
      "ex" => []
    }

    {Map.update!(state, "routines", &(&1 ++ [routine])), routine["id"]}
  end

  def update_routine(state, id, attrs) do
    update_in(state["routines"], fn routines ->
      Enum.map(routines, fn
        %{"id" => ^id} = routine -> Map.merge(routine, attrs)
        routine -> routine
      end)
    end)
  end

  def apply_ai_week(state, %{"days" => days} = plan, generated_on \\ Date.utc_today()) do
    dates = Enum.map(days, & &1["date"])

    # Applying a new AI plan must never delete an existing routine. Exact-date and recurring
    # assignments can point at the new routines while every user-created or older AI routine
    # remains available in the routine library.
    state = update_in(state["dayPlan"], &Map.drop(&1, dates))

    {routines, day_plan} =
      Enum.reduce(days, {state["routines"], state["dayPlan"]}, fn day, {routines, day_plan} ->
        if day["kind"] == "rest" do
          {routines, Map.put(day_plan, day["date"], "rest")}
        else
          routine_id = uid("routine")

          exercises = Enum.map(day["exercises"], &ai_exercise_config(state, &1))

          routine = %{
            "id" => routine_id,
            "name" => present(day["name"], "AI workout"),
            "emoji" => "sparkles",
            "ex" => exercises,
            "source" => "ai",
            "plannedFor" => day["date"],
            "generatedOn" => Date.to_iso8601(generated_on),
            "rationale" => day["rationale"] || "",
            "planSummary" => plan["summary"] || ""
          }

          {routines ++ [routine], Map.put(day_plan, day["date"], routine_id)}
        end
      end)

    weekly_plan =
      Enum.reduce(days, state["week"], fn day, week ->
        case Date.from_iso8601(day["date"]) do
          {:ok, date} ->
            weekday = Integer.to_string(rem(Date.day_of_week(date), 7))

            case day_plan[day["date"]] do
              "rest" -> Map.delete(week, weekday)
              routine_id when is_binary(routine_id) -> Map.put(week, weekday, routine_id)
              _value -> week
            end

          _error ->
            week
        end
      end)

    state
    |> Map.put("routines", routines)
    |> Map.put("dayPlan", day_plan)
    |> Map.put("week", weekly_plan)
  end

  def apply_ai_day(state, day, draft, generated_on \\ Date.utc_today())

  def apply_ai_day(
        state,
        day,
        %{"exercises" => prescriptions} = draft,
        generated_on
      ) do
    day = to_string(day)

    if day in ~w(0 1 2 3 4 5 6) do
      routine_id = uid("routine")

      exercises = Enum.map(prescriptions, &ai_exercise_config(state, &1))

      routine = %{
        "id" => routine_id,
        "name" => present(draft["name"], "AI routine"),
        "emoji" => "sparkles",
        "ex" => exercises,
        "source" => "ai",
        "plannedWeekday" => day,
        "generatedOn" => Date.to_iso8601(generated_on),
        "rationale" => draft["rationale"] || "",
        "muscleGroups" => List.wrap(draft["muscle_groups"])
      }

      state
      |> update_in(["routines"], &(&1 ++ [routine]))
      |> put_in(["week", day], routine_id)
    else
      state
    end
  end

  def apply_ai_day(state, _day, _draft, _generated_on), do: state

  def delete_routine(state, id) do
    state
    |> update_in(["routines"], &Enum.reject(&1, fn routine -> routine["id"] == id end))
    |> update_in(["week"], fn week ->
      Map.new(week, fn {day, value} -> {day, if(value == id, do: nil, else: value)} end)
      |> reject_nil_values()
    end)
    |> update_in(["dayPlan"], fn plan ->
      Map.new(plan, fn {date, value} -> {date, if(value == id, do: "rest", else: value)} end)
    end)
  end

  def assign_day(state, day, ""), do: update_in(state["week"], &Map.delete(&1, day))
  def assign_day(state, day, nil), do: assign_day(state, day, "")
  def assign_day(state, day, routine_id), do: put_in(state, ["week", day], routine_id)

  def add_sport(state, attrs) when is_map(attrs) do
    sport = %{
      "id" => uid("sport"),
      "name" => attrs["name"] |> normalized_text() |> String.slice(0, 80),
      "day" => normalized_text(attrs["day"]),
      "start" => normalized_text(attrs["start"]),
      "duration" => normalized_duration(attrs["duration"])
    }

    if valid_sport?(sport) do
      Map.update(state, "sports", [sport], &(List.wrap(&1) ++ [sport]))
    else
      state
    end
  end

  def add_sport(state, _attrs), do: state

  def remove_sport(state, id) do
    Map.update(state, "sports", [], fn sports ->
      Enum.reject(List.wrap(sports), fn
        %{} = sport -> sport["id"] == id
        _sport -> false
      end)
    end)
  end

  def sports_for_day(state, day) do
    day = to_string(day)

    state["sports"]
    |> List.wrap()
    |> Enum.filter(fn
      %{} = sport -> sport["day"] == day
      _sport -> false
    end)
    |> Enum.sort_by(&{&1["start"], &1["name"]})
  end

  def assign_date(state, date, ""), do: update_in(state["dayPlan"], &Map.delete(&1, date))
  def assign_date(state, date, nil), do: assign_date(state, date, "")
  def assign_date(state, date, routine_id), do: put_in(state, ["dayPlan", date], routine_id)

  def add_routine_exercise(state, routine_id, exercise_id) do
    exercise = Catalogue.get(exercise_id)
    bodyweight = exercise && exercise["eq"] == "body weight"

    config = %{
      "id" => exercise_id,
      "sets" => 3,
      "reps" => 10,
      "weight" => 0,
      "mode" => "reps",
      "bodyweight" => bodyweight
    }

    update_routine_exercises(state, routine_id, &(&1 ++ [config]))
  end

  def remove_routine_exercise(state, routine_id, index) do
    update_routine_exercises(state, routine_id, &List.delete_at(&1, index))
  end

  def configure_routine_exercise(state, routine_id, index, attrs) do
    update_routine_exercises(state, routine_id, fn exercises ->
      List.update_at(exercises, index, &Map.merge(&1, attrs))
    end)
  end

  def effective_routine(state, date \\ Date.utc_today()) do
    iso = Date.to_iso8601(date)

    id =
      case state["dayPlan"][iso] do
        "rest" -> nil
        id when is_binary(id) -> id
        _ -> state["week"][Integer.to_string(rem(Date.day_of_week(date), 7))]
      end

    Enum.find(state["routines"], &(&1["id"] == id))
  end

  def start_workout(state, routine_id, body_weight \\ nil) do
    routine = Enum.find(state["routines"], &(&1["id"] == routine_id))
    configs = if routine, do: routine["ex"], else: []

    entries = Enum.map(configs, &entry_from_config/1)

    active = %{
      "id" => uid("workout"),
      "d" => Date.to_iso8601(Date.utc_today()),
      "start" => now_ms(),
      "routineId" => routine && routine["id"],
      "name" => (routine && routine["name"]) || "Freestyle",
      "bw" => body_weight,
      "cur" => 0,
      "entries" => entries
    }

    Map.put(state, "active", active)
  end

  def add_active_exercise(%{"active" => nil} = state, _exercise_id), do: state

  def add_active_exercise(state, exercise_id) do
    config = %{"id" => exercise_id, "sets" => 3, "reps" => 10, "weight" => 0, "mode" => "reps"}
    entries = state["active"]["entries"] ++ [entry_from_config(config)]

    state
    |> put_in(["active", "entries"], entries)
    |> put_in(["active", "cur"], length(entries) - 1)
  end

  def remove_active_exercise(state, index) do
    entries = List.delete_at(state["active"]["entries"], index)
    current = min(state["active"]["cur"] || 0, max(length(entries) - 1, 0))

    state
    |> put_in(["active", "entries"], entries)
    |> put_in(["active", "cur"], current)
  end

  def swap_active_exercise(%{"active" => nil} = state, _index, _exercise_id), do: state

  def swap_active_exercise(state, index, exercise_id) do
    entries = state["active"]["entries"]
    current = Enum.at(entries, index)

    if current do
      exercise = Catalogue.get(exercise_id)

      bodyweight? = exercise && exercise["eq"] == "body weight"

      target =
        (current["target"] || %{})
        |> Map.put("id", exercise_id)
        |> Map.put("bodyweight", bodyweight?)

      sets =
        Enum.map(current["sets"], fn set ->
          set = Map.put(set, "done", false)

          if bodyweight? do
            set = set |> Map.put("w", 0.0) |> Map.delete("drops")
            if set["type"] == "dropset", do: Map.delete(set, "type"), else: set
          else
            set
          end
        end)

      replacement = %{"id" => exercise_id, "target" => target, "sets" => sets}

      if Enum.any?(current["sets"], & &1["done"]) do
        entries = List.insert_at(entries, index + 1, replacement)

        state
        |> put_in(["active", "entries"], entries)
        |> put_in(["active", "cur"], index + 1)
      else
        put_in(state, ["active", "entries"], List.replace_at(entries, index, replacement))
      end
    else
      state
    end
  end

  def set_active_index(%{"active" => nil} = state, _index), do: state

  def set_active_index(state, index) do
    last = max(length(state["active"]["entries"]) - 1, 0)
    put_in(state, ["active", "cur"], index |> max(0) |> min(last))
  end

  def move_active_exercise(%{"active" => nil} = state, _direction), do: state

  def move_active_exercise(state, direction) do
    entries = state["active"]["entries"]
    current = state["active"]["cur"] || 0
    target = current + direction

    if entries != [] and current in 0..(length(entries) - 1) and
         target in 0..(length(entries) - 1) do
      current_entry = Enum.at(entries, current)
      target_entry = Enum.at(entries, target)

      entries =
        entries
        |> List.replace_at(current, target_entry)
        |> List.replace_at(target, current_entry)

      state
      |> put_in(["active", "entries"], entries)
      |> put_in(["active", "cur"], target)
    else
      state
    end
  end

  def add_set(state, entry_index) do
    update_active_entry(state, entry_index, fn entry ->
      previous =
        entry["sets"]
        |> Enum.reverse()
        |> Enum.find(&(not warmup_set?(&1)))
        |> then(&(&1 || %{"w" => 0, "r" => 10}))

      set = %{
        "w" => number(previous["w"]),
        "r" => max(0, integer(previous["r"], 10)),
        "done" => false,
        "phase" => "work"
      }

      Map.update!(entry, "sets", &(&1 ++ [set]))
    end)
  end

  def add_warmup_set(state, entry_index) do
    update_active_entry(state, entry_index, fn entry ->
      first_work =
        Enum.find(entry["sets"], &(not warmup_set?(&1))) || List.first(entry["sets"]) || %{}

      weight = number(first_work["w"])
      warmup_weight = Float.round(weight * 0.5 / 2.5) * 2.5

      warmup = %{
        "w" => warmup_weight,
        "r" => max(1, integer(first_work["r"], 10)),
        "done" => false,
        "phase" => "warmup"
      }

      warmup_count = Enum.count(entry["sets"], &warmup_set?/1)
      Map.update!(entry, "sets", &List.insert_at(&1, warmup_count, warmup))
    end)
  end

  def remove_set(state, entry_index, set_index) do
    update_active_entry(state, entry_index, fn entry ->
      sets =
        if length(entry["sets"]) > 1,
          do: List.delete_at(entry["sets"], set_index),
          else: entry["sets"]

      Map.put(entry, "sets", sets)
    end)
  end

  def update_set(state, entry_index, set_index, attrs) do
    update_active_entry(state, entry_index, fn entry ->
      sets = entry["sets"]
      selected_set = if set_index >= 0, do: Enum.at(sets, set_index)

      updated_sets =
        sets
        |> Enum.with_index()
        |> Enum.map(fn {set, index} ->
          copy_to_following_set? =
            selected_set && not warmup_set?(selected_set) && index > set_index &&
              not warmup_set?(set) && not set["done"]

          if index == set_index || copy_to_following_set?, do: Map.merge(set, attrs), else: set
        end)

      Map.put(entry, "sets", updated_sets)
    end)
  end

  def step_set(%{"active" => nil} = state, _entry_index, _set_index, _field, _direction),
    do: state

  def step_set(state, entry_index, set_index, field, direction) when field in ~w(w r) do
    entry = Enum.at(state["active"]["entries"], entry_index)
    set = entry && Enum.at(entry["sets"], set_index)

    if set do
      step = if field == "w", do: 2.5, else: 1
      current = if field == "w", do: number(set[field]), else: integer(set[field], 0)
      value = max(0, current + direction * step)
      value = if field == "r", do: trunc(value), else: value
      update_set(state, entry_index, set_index, %{field => value})
    else
      state
    end
  end

  def toggle_set(state, entry_index, set_index) do
    update_active_entry(state, entry_index, fn entry ->
      update_in(entry["sets"], fn sets ->
        List.update_at(sets, set_index, &Map.update(&1, "done", true, fn done -> not done end))
      end)
    end)
  end

  def add_drop(state, entry_index, set_index) do
    update_active_entry(state, entry_index, fn entry ->
      sets =
        List.update_at(entry["sets"], set_index, fn set ->
          if warmup_set?(set) do
            set
          else
            drops = List.wrap(set["drops"])
            base_weight = number((List.last(drops) || set)["w"])
            drop = %{"w" => Float.round(base_weight * 0.8 * 2) / 2, "r" => integer(set["r"], 0)}

            set
            |> Map.put("type", "dropset")
            |> Map.put("drops", drops ++ [drop])
          end
        end)

      Map.put(entry, "sets", sets)
    end)
  end

  def step_drop(state, entry_index, set_index, drop_index, field, direction)
      when field in ~w(w r) do
    update_active_entry(state, entry_index, fn entry ->
      sets =
        List.update_at(entry["sets"], set_index, fn set ->
          drops = List.wrap(set["drops"])

          case Enum.at(drops, drop_index) do
            nil ->
              set

            drop ->
              step = if field == "w", do: 2.5, else: 1
              previous = if field == "w", do: number(drop[field]), else: integer(drop[field], 0)
              value = max(0, previous + direction * step)
              value = if field == "r", do: trunc(value), else: value

              Map.put(
                set,
                "drops",
                List.replace_at(drops, drop_index, Map.put(drop, field, value))
              )
          end
        end)

      Map.put(entry, "sets", sets)
    end)
  end

  def remove_drop(state, entry_index, set_index, drop_index) do
    update_active_entry(state, entry_index, fn entry ->
      sets =
        List.update_at(entry["sets"], set_index, fn set ->
          drops = set["drops"] |> List.wrap() |> List.delete_at(drop_index)

          if drops == [] do
            set |> Map.delete("drops") |> Map.delete("type")
          else
            Map.put(set, "drops", drops)
          end
        end)

      Map.put(entry, "sets", sets)
    end)
  end

  def warmup_set?(set) when is_map(set),
    do: set["phase"] == "warmup" || set["warmup"] == true

  def warmup_set?(_set), do: false

  def finish_workout(%{"active" => nil} = state), do: state

  def finish_workout(state) do
    ended = now_ms()
    active = state["active"]
    volume = workout_volume(active)
    completed = active |> Map.put("end", ended) |> Map.put("vol", volume) |> Map.delete("cur")

    state
    |> Map.put("active", nil)
    |> Map.update!("workouts", &(&1 ++ [completed]))
  end

  def cancel_workout(state), do: Map.put(state, "active", nil)

  def delete_workout(state, id) do
    update_in(state["workouts"], &Enum.reject(&1, fn workout -> workout["id"] == id end))
  end

  def add_body_weight(state, weight, date \\ Date.utc_today()) do
    iso = Date.to_iso8601(date)
    row = %{"d" => iso, "w" => weight, "t" => now_ms()}

    update_in(state["bodyweight"], fn rows ->
      rows
      |> Enum.reject(&(&1["d"] == iso))
      |> Kernel.++([row])
      |> Enum.sort_by(& &1["d"])
    end)
  end

  def delete_body_weight(state, index),
    do: update_in(state["bodyweight"], &List.delete_at(&1, index))

  def add_custom_exercise(state, name, body_part, equipment) do
    exercise = %{
      "id" => uid("custom"),
      "n" => present(name, "Custom exercise"),
      "bp" => present(body_part, "other"),
      "eq" => present(equipment, "other"),
      "tg" => present(body_part, "other"),
      "sm" => [],
      "st" => []
    }

    Map.update!(state, "customEx", &(&1 ++ [exercise]))
  end

  def update_preference(state, key, value)
      when key in ~w(unit restSec lang theme accent) do
    Map.put(state, key, value)
  end

  def workout_volume(workout) do
    workout
    |> Map.get("entries", [])
    |> Enum.flat_map(&Map.get(&1, "sets", []))
    |> Enum.filter(&(&1["done"] && not warmup_set?(&1)))
    |> Enum.reduce(0.0, fn set, total ->
      drop_volume =
        set["drops"]
        |> List.wrap()
        |> Enum.reduce(0.0, fn drop, volume ->
          volume + number(drop["w"]) * number(drop["r"])
        end)

      total + number(set["w"]) * number(set["r"]) + drop_volume
    end)
  end

  def stats(state) do
    workouts = state["workouts"]

    sets =
      workouts
      |> Enum.flat_map(& &1["entries"])
      |> Enum.flat_map(& &1["sets"])
      |> Enum.count(& &1["done"])

    volume =
      Enum.reduce(workouts, 0.0, fn workout, total ->
        total + number(workout["vol"] || workout_volume(workout))
      end)

    %{workouts: length(workouts), sets: sets, volume: volume, routines: length(state["routines"])}
  end

  def number(value) when is_integer(value), do: value * 1.0
  def number(value) when is_float(value), do: value

  def number(value) when is_binary(value) do
    case value |> String.replace(",", ".") |> Float.parse() do
      {number, _} -> number
      :error -> 0.0
    end
  end

  def number(_value), do: 0.0

  def integer(value, fallback \\ 0) do
    case Integer.parse(to_string(value)) do
      {number, _} -> number
      :error -> fallback
    end
  end

  defp ai_exercise_config(state, prescription) do
    item =
      Enum.find(state["customEx"], &(&1["id"] == prescription["exercise_id"])) ||
        Catalogue.get(prescription["exercise_id"])

    sets = max(1, integer(prescription["sets"], 3))

    config = %{
      "id" => prescription["exercise_id"],
      "sets" => sets,
      "reps" => max(1, integer(prescription["reps"], 10)),
      "weight" => max(0.0, number(prescription["weight"])),
      "restSec" => max(30, integer(prescription["rest_seconds"], 90)),
      "note" => prescription["note"] || "",
      "mode" => "reps",
      "bodyweight" => item && item["eq"] == "body weight"
    }

    case normalize_ai_technique(prescription["last_set_technique"]) do
      nil -> config
      technique -> Map.put(config, "setTechniques", List.duplicate(nil, sets - 1) ++ [technique])
    end
  end

  defp normalize_ai_technique(%{"type" => "dropset"} = technique) do
    %{
      "type" => "dropset",
      "count" => technique["count"] |> integer(1) |> max(1) |> min(2),
      "pct" => technique["pct"] |> integer(20) |> max(10) |> min(40)
    }
  end

  defp normalize_ai_technique(_technique), do: nil

  defp entry_from_config(config) do
    count = max(1, integer(config["sets"], 3))

    sets =
      for _index <- 1..count do
        %{
          "w" => number(config["weight"]),
          "r" => max(0, integer(config["reps"], 10)),
          "done" => false
        }
      end
      |> apply_planned_intensifier(config)

    %{"id" => config["id"], "target" => config, "sets" => sets}
  end

  defp apply_planned_intensifier(sets, %{"setTechniques" => techniques})
       when is_list(techniques) and techniques != [] do
    sets
    |> Enum.with_index()
    |> Enum.map(fn {set, index} ->
      apply_planned_set_technique(set, Enum.at(techniques, index))
    end)
  end

  defp apply_planned_intensifier(sets, %{"intensifier" => %{"type" => "dropset"} = plan}) do
    count = max(1, integer(plan["count"], 1))
    percentage = plan["pct"] |> integer(20) |> max(5) |> min(90)

    Enum.map(sets, fn set ->
      {drops, _weight} =
        Enum.map_reduce(1..count, number(set["w"]), fn _index, previous ->
          weight = Float.round(previous * (1 - percentage / 100) * 2) / 2
          {%{"w" => weight, "r" => set["r"]}, weight}
        end)

      set |> Map.put("type", "dropset") |> Map.put("drops", drops)
    end)
  end

  defp apply_planned_intensifier(sets, _config), do: sets

  defp apply_planned_set_technique(set, %{"type" => "dropset"} = plan) do
    apply_planned_intensifier([set], %{"intensifier" => plan}) |> List.first()
  end

  defp apply_planned_set_technique(set, _technique), do: set

  defp normalize_sports(state) do
    sports =
      state["sports"]
      |> List.wrap()
      |> Enum.flat_map(fn
        %{} = sport ->
          normalized = %{
            "id" => sport["id"] |> normalized_text() |> String.slice(0, 120),
            "name" => sport["name"] |> normalized_text() |> String.slice(0, 80),
            "day" => normalized_text(sport["day"]),
            "start" => normalized_text(sport["start"]),
            "duration" => normalized_duration(sport["duration"])
          }

          if valid_sport?(normalized), do: [normalized], else: []

        _sport ->
          []
      end)

    Map.put(state, "sports", sports)
  end

  defp valid_sport?(sport) do
    sport["id"] != "" && sport["name"] != "" && sport["day"] in ~w(0 1 2 3 4 5 6) &&
      Regex.match?(~r/^(?:[01]\d|2[0-3]):[0-5]\d$/, sport["start"]) &&
      sport["duration"] in 1..1440
  end

  defp normalized_duration(value) when is_integer(value), do: value
  defp normalized_duration(value) when is_binary(value), do: integer(value)
  defp normalized_duration(_value), do: 0

  defp normalized_text(value) when is_binary(value), do: String.trim(value)
  defp normalized_text(value) when is_integer(value), do: Integer.to_string(value)
  defp normalized_text(_value), do: ""

  defp strip_rest_pause_data(state) do
    state
    |> Map.update!("routines", fn routines ->
      Enum.map(routines, fn routine ->
        Map.update(routine, "ex", [], fn configs ->
          Enum.map(configs, &strip_rest_pause_config/1)
        end)
      end)
    end)
    |> Map.update!("workouts", fn workouts ->
      Enum.map(workouts, &strip_rest_pause_workout/1)
    end)
    |> Map.update!("active", fn
      nil -> nil
      workout -> strip_rest_pause_workout(workout)
    end)
  end

  defp strip_rest_pause_workout(workout) do
    Map.update(workout, "entries", [], fn entries ->
      Enum.map(entries, fn entry ->
        entry =
          case entry["target"] do
            target when is_map(target) ->
              Map.put(entry, "target", strip_rest_pause_config(target))

            _target ->
              entry
          end

        Map.update(entry, "sets", [], fn sets -> Enum.map(sets, &strip_rest_pause_set/1) end)
      end)
    end)
  end

  defp strip_rest_pause_config(config) do
    config =
      case config["setTechniques"] do
        techniques when is_list(techniques) ->
          Map.put(
            config,
            "setTechniques",
            Enum.map(techniques, fn
              %{"type" => "dropset"} = technique -> technique
              _technique -> nil
            end)
          )

        _techniques ->
          config
      end

    case config["intensifier"] do
      %{"type" => "dropset"} -> config
      nil -> config
      _removed_technique -> Map.delete(config, "intensifier")
    end
  end

  defp strip_rest_pause_set(set) do
    set = Map.delete(set, "clusters")
    if set["type"] == "restpause", do: Map.delete(set, "type"), else: set
  end

  defp update_routine_exercises(state, routine_id, callback) do
    update_in(state["routines"], fn routines ->
      Enum.map(routines, fn
        %{"id" => ^routine_id} = routine -> Map.update(routine, "ex", [], callback)
        routine -> routine
      end)
    end)
  end

  defp update_active_entry(%{"active" => nil} = state, _index, _callback), do: state

  defp update_active_entry(state, index, callback),
    do: update_in(state["active"]["entries"], &List.update_at(&1, index, callback))

  defp reject_nil_values(map), do: Map.reject(map, fn {_key, value} -> is_nil(value) end)

  defp present(value, fallback),
    do: if(String.trim(to_string(value)) == "", do: fallback, else: String.trim(to_string(value)))

  defp now_ms, do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)

  defp uid(prefix),
    do:
      "#{prefix}-#{System.unique_integer([:positive, :monotonic])}-#{Base.url_encode64(:crypto.strong_rand_bytes(5), padding: false)}"
end
