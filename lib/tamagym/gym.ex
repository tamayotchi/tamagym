defmodule Tamagym.Gym do
  @moduledoc "Relational per-user gym data persisted in SQLite."

  import Ecto.Query, warn: false

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

  # exWeights is accepted only so old browser caches are discarded instead of becoming a setting.
  @non_setting_keys ~w(routines dayPlan workouts active bodyweight customEx exWeights)
  @routine_keys ~w(id name emoji)
  @workout_keys ~w(id d start end routineId name bw vol)

  def get_data(%User{id: user_id}) do
    settings =
      case Repo.get_by(UserSettings, user_id: user_id) do
        nil -> %{}
        row -> row.data
      end
      |> Map.put_new("week", %{})

    Map.merge(settings, %{
      "routines" => serialize_routines(user_id),
      "dayPlan" => serialize_day_overrides(user_id),
      "workouts" => serialize_workouts(user_id, "completed"),
      "active" => serialize_active(user_id),
      "bodyweight" => serialize_body_weights(user_id),
      "customEx" => serialize_custom_exercises(user_id)
    })
  end

  def put_data(%User{id: user_id} = user, data) when is_map(data) do
    Repo.transaction(fn ->
      # LiveView and the compatibility API submit one state document. Compare each relational
      # collection independently so changing one active set does not rewrite unchanged history.
      current = get_data(user)
      settings = Map.drop(data, @non_setting_keys)
      routines = collection(data, "routines")
      week = object(data, "week")
      day_plan = object(data, "dayPlan")
      completed_workouts = collection(data, "workouts")
      active = active_value(data)
      body_weights = collection(data, "bodyweight")
      custom_exercises = collection(data, "customEx")

      unless equivalent?(settings, Map.drop(current, @non_setting_keys)) do
        replace_settings(user_id, settings)
      end

      routines_changed = not equivalent?(routines, current["routines"])
      day_plan_changed = not equivalent?(day_plan, current["dayPlan"])

      routine_index =
        if routines_changed do
          delete_day_overrides(user_id)
          Repo.delete_all(from r in Routine, where: r.user_id == ^user_id)
          routines = insert_routines(user_id, routines)
          insert_day_overrides(user_id, day_plan, routines)
          routines
        else
          routines_by_client_id(user_id)
        end

      validate_week(week, routine_index)

      if not routines_changed and day_plan_changed do
        delete_day_overrides(user_id)
        insert_day_overrides(user_id, day_plan, routine_index)
      end

      completed_changed = not equivalent?(completed_workouts, current["workouts"])
      active_changed = not equivalent?(active, current["active"])

      if completed_changed, do: delete_workouts(user_id, "completed")
      if active_changed, do: delete_workouts(user_id, "active")
      if completed_changed, do: insert_completed_workouts(user_id, completed_workouts)
      if active_changed, do: insert_active_workout(user_id, active)

      unless equivalent?(body_weights, current["bodyweight"]) do
        Repo.delete_all(from b in BodyWeight, where: b.user_id == ^user_id)
        insert_body_weights(user_id, body_weights)
      end

      unless equivalent?(custom_exercises, current["customEx"]) do
        Repo.delete_all(from e in CustomExercise, where: e.user_id == ^user_id)
        insert_custom_exercises(user_id, custom_exercises)
      end

      :ok
    end)
  end

  defp serialize_routines(user_id) do
    Repo.all(from r in Routine, where: r.user_id == ^user_id, order_by: r.position)
    |> Enum.map(fn routine ->
      routine.data
      |> Map.merge(%{"id" => routine.client_id, "name" => routine.name})
      |> put_if("emoji", routine.emoji)
    end)
  end

  defp serialize_day_overrides(user_id) do
    Repo.all(
      from o in DayOverride,
        left_join: r in Routine,
        on: r.id == o.routine_id,
        where: o.user_id == ^user_id,
        select: {o.planned_on, o.kind, r.client_id}
    )
    |> Map.new(fn
      {date, "rest", _client_id} -> {Date.to_iso8601(date), "rest"}
      {date, "routine", client_id} -> {Date.to_iso8601(date), client_id}
    end)
  end

  defp serialize_workouts(user_id, status) do
    Repo.all(
      from w in Workout,
        where: w.user_id == ^user_id and w.status == ^status,
        order_by: w.position
    )
    |> Enum.map(&serialize_workout/1)
  end

  defp serialize_active(user_id) do
    case Repo.get_by(Workout, user_id: user_id, status: "active") do
      nil -> nil
      workout -> serialize_workout(workout)
    end
  end

  defp serialize_workout(workout) do
    workout.data
    |> Map.merge(%{"id" => workout.client_id, "d" => Date.to_iso8601(workout.performed_on)})
    |> put_if("start", workout.started_at_ms)
    |> put_if("end", workout.ended_at_ms)
    |> put_if("routineId", workout.routine_client_id)
    |> put_if("name", workout.name)
    |> put_if("bw", workout.body_weight)
    |> put_if("vol", workout.volume)
  end

  defp serialize_body_weights(user_id) do
    Repo.all(from b in BodyWeight, where: b.user_id == ^user_id, order_by: b.position)
    |> Enum.map(fn row ->
      row.data
      |> Map.merge(%{"d" => Date.to_iso8601(row.weighed_on), "w" => row.weight})
      |> put_if("t", row.recorded_at_ms)
    end)
  end

  defp serialize_custom_exercises(user_id) do
    Repo.all(from e in CustomExercise, where: e.user_id == ^user_id, order_by: e.position)
    |> Enum.map(fn row -> Map.merge(row.data, %{"id" => row.exercise_id, "n" => row.name}) end)
  end

  defp replace_settings(user_id, data) do
    settings = Repo.get_by(UserSettings, user_id: user_id) || %UserSettings{user_id: user_id}
    insert_or_rollback(UserSettings.changeset(settings, %{user_id: user_id, data: data}))
  end

  defp routines_by_client_id(user_id) do
    Repo.all(from r in Routine, where: r.user_id == ^user_id)
    |> Map.new(&{&1.client_id, &1})
  end

  defp delete_day_overrides(user_id) do
    Repo.delete_all(from o in DayOverride, where: o.user_id == ^user_id)
  end

  defp delete_workouts(user_id, status) do
    Repo.delete_all(from w in Workout, where: w.user_id == ^user_id and w.status == ^status)
  end

  defp insert_routines(user_id, routines) do
    routines
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {payload, position}, by_client_id ->
      payload = require_object(payload, "routine")
      client_id = required_string(payload, "id")

      validate_routine_exercises(payload)

      routine =
        %Routine{}
        |> Routine.changeset(%{
          user_id: user_id,
          client_id: client_id,
          position: position,
          name: string(payload, "name") || "Routine",
          emoji: string(payload, "emoji"),
          data: Map.drop(payload, @routine_keys)
        })
        |> insert_or_rollback()

      Map.put(by_client_id, client_id, routine)
    end)
  end

  defp validate_week(week, routines) do
    Enum.each(week, fn {weekday, client_id} ->
      parse_weekday(weekday)
      routine_for(routines, client_id)
    end)
  end

  defp insert_day_overrides(user_id, overrides, routines) do
    Enum.each(overrides, fn {date, value} ->
      attrs =
        if value == "rest" do
          %{user_id: user_id, planned_on: date, kind: "rest", routine_id: nil}
        else
          routine = routine_for(routines, value)
          %{user_id: user_id, planned_on: date, kind: "routine", routine_id: routine.id}
        end

      %DayOverride{}
      |> DayOverride.changeset(attrs)
      |> insert_or_rollback()
    end)
  end

  defp insert_completed_workouts(user_id, completed) do
    completed
    |> Enum.with_index()
    |> Enum.each(fn {payload, position} ->
      insert_workout(user_id, require_object(payload, "workout"), "completed", position)
    end)
  end

  defp insert_active_workout(_user_id, nil), do: :ok
  defp insert_active_workout(user_id, active), do: insert_workout(user_id, active, "active", 0)

  defp insert_workout(user_id, payload, status, position) do
    validate_workout_entries(payload)

    %Workout{}
    |> Workout.changeset(%{
      user_id: user_id,
      client_id: required_string(payload, "id"),
      position: position,
      status: status,
      performed_on: required_string(payload, "d"),
      routine_client_id: string(payload, "routineId"),
      name: string(payload, "name"),
      started_at_ms: value(payload, "start"),
      ended_at_ms: value(payload, "end"),
      body_weight: value(payload, "bw"),
      volume: value(payload, "vol"),
      data: Map.drop(payload, @workout_keys)
    })
    |> insert_or_rollback()
  end

  defp insert_body_weights(user_id, body_weights) do
    body_weights
    |> Enum.with_index()
    |> Enum.each(fn {payload, position} ->
      payload = require_object(payload, "body weight")

      %BodyWeight{}
      |> BodyWeight.changeset(%{
        user_id: user_id,
        position: position,
        weighed_on: required_string(payload, "d"),
        weight: value(payload, "w"),
        recorded_at_ms: value(payload, "t"),
        data: Map.drop(payload, ~w(d w t))
      })
      |> insert_or_rollback()
    end)
  end

  defp insert_custom_exercises(user_id, exercises) do
    exercises
    |> Enum.with_index()
    |> Enum.each(fn {payload, position} ->
      payload = require_object(payload, "custom exercise")

      %CustomExercise{}
      |> CustomExercise.changeset(%{
        user_id: user_id,
        position: position,
        exercise_id: required_string(payload, "id"),
        name: required_string(payload, "n"),
        data: Map.drop(payload, ~w(id n))
      })
      |> insert_or_rollback()
    end)
  end

  defp insert_or_rollback(changeset) do
    case Repo.insert_or_update(changeset) do
      {:ok, row} -> row
      {:error, changeset} -> Repo.rollback({:invalid_state, changeset})
    end
  end

  defp routine_for(routines, client_id) do
    case Map.get(routines, to_string(client_id)) do
      nil -> Repo.rollback({:invalid_state, "unknown routine #{inspect(client_id)}"})
      routine -> routine
    end
  end

  defp parse_weekday(value) do
    case Integer.parse(to_string(value)) do
      {weekday, ""} when weekday in 0..6 -> weekday
      _ -> Repo.rollback({:invalid_state, "invalid weekday #{inspect(value)}"})
    end
  end

  defp collection(map, key) do
    case value(map, key) do
      nil -> []
      list when is_list(list) -> list
      _ -> Repo.rollback({:invalid_state, "#{key} must be an array"})
    end
  end

  defp object(map, key) do
    case value(map, key) do
      nil -> %{}
      value when is_map(value) -> value
      _ -> Repo.rollback({:invalid_state, "#{key} must be an object"})
    end
  end

  defp active_value(map) do
    case value(map, "active") do
      nil -> nil
      active when is_map(active) -> active
      _ -> Repo.rollback({:invalid_state, "active must be an object or null"})
    end
  end

  defp validate_routine_exercises(routine) do
    Enum.each(collection(routine, "ex"), fn exercise ->
      exercise = require_object(exercise, "routine exercise")
      required_string(exercise, "id")
    end)
  end

  defp validate_workout_entries(workout) do
    Enum.each(collection(workout, "entries"), fn entry ->
      entry = require_object(entry, "workout exercise")
      required_string(entry, "id")

      Enum.each(collection(entry, "sets"), fn set ->
        require_object(set, "workout set")
      end)
    end)
  end

  defp equivalent?(left, right), do: canonical(left) == canonical(right)

  defp canonical(value) when is_list(value), do: Enum.map(value, &canonical/1)

  defp canonical(value) when is_map(value) do
    value
    |> Enum.reject(fn {_key, item} -> is_nil(item) end)
    |> Map.new(fn {key, item} -> {key, canonical(item)} end)
  end

  defp canonical(value), do: value

  defp require_object(value, _name) when is_map(value), do: value

  defp require_object(_value, name) do
    Repo.rollback({:invalid_state, "#{name} must be an object"})
  end

  defp required_string(map, key) do
    case string(map, key) do
      nil -> Repo.rollback({:invalid_state, "#{key} is required"})
      value -> value
    end
  end

  defp string(map, key) do
    case value(map, key) do
      value when is_binary(value) and byte_size(value) > 0 -> value
      _ -> nil
    end
  end

  defp value(map, key), do: Map.get(map, key)

  defp put_if(map, _key, nil), do: map
  defp put_if(map, key, value), do: Map.put(map, key, value)
end
