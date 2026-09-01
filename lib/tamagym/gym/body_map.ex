defmodule Tamagym.Gym.BodyMap do
  @moduledoc "Muscle load and SVG geometry for routine and workout coverage diagrams."

  alias Tamagym.Gym.Catalogue

  @external_resource Path.expand("../../../priv/catalogue/body_paths.json", __DIR__)
  @geometry @external_resource |> File.read!() |> Jason.decode!()

  @muscles ~w(trapezius deltoids chest upper-back serratus biceps triceps forearm abs obliques lower-back gluteal quadriceps hamstring adductors hip-flexors calves tibialis)
  @inert ~w(head hair neck hands feet knees ankles)

  @names %{
    "trapezius" => "Traps",
    "deltoids" => "Shoulders",
    "chest" => "Chest",
    "upper-back" => "Upper back",
    "serratus" => "Serratus",
    "biceps" => "Biceps",
    "triceps" => "Triceps",
    "forearm" => "Forearms",
    "abs" => "Abs",
    "obliques" => "Obliques",
    "lower-back" => "Lower back",
    "gluteal" => "Glutes",
    "quadriceps" => "Quads",
    "hamstring" => "Hamstrings",
    "adductors" => "Adductors",
    "hip-flexors" => "Hip flexors",
    "calves" => "Calves",
    "tibialis" => "Shins"
  }

  @aliases %{
    "abs" => "abs",
    "abdominals" => "abs",
    "lower abs" => "abs",
    "core" => "abs",
    "pectorals" => "chest",
    "chest" => "chest",
    "upper chest" => "chest",
    "biceps" => "biceps",
    "brachialis" => "biceps",
    "glutes" => "gluteal",
    "abductors" => "gluteal",
    "delts" => "deltoids",
    "deltoids" => "deltoids",
    "shoulders" => "deltoids",
    "rear deltoids" => "deltoids",
    "rotator cuff" => "deltoids",
    "triceps" => "triceps",
    "upper back" => "upper-back",
    "lats" => "upper-back",
    "back" => "upper-back",
    "rhomboids" => "upper-back",
    "latissimus dorsi" => "upper-back",
    "calves" => "calves",
    "soleus" => "calves",
    "quads" => "quadriceps",
    "quadriceps" => "quadriceps",
    "forearms" => "forearm",
    "wrists" => "forearm",
    "wrist flexors" => "forearm",
    "wrist extensors" => "forearm",
    "grip muscles" => "forearm",
    "hamstrings" => "hamstring",
    "spine" => "lower-back",
    "lower back" => "lower-back",
    "traps" => "trapezius",
    "trapezius" => "trapezius",
    "levator scapulae" => "trapezius",
    "adductors" => "adductors",
    "groin" => "adductors",
    "inner thighs" => "adductors",
    "serratus anterior" => "serratus",
    "hip flexors" => "hip-flexors",
    "obliques" => "obliques",
    "shins" => "tibialis"
  }

  @body_parts %{
    "chest" => %{"chest" => 1.0},
    "back" => %{"upper-back" => 0.75, "lower-back" => 0.25},
    "shoulders" => %{"deltoids" => 1.0},
    "upper arms" => %{"biceps" => 0.5, "triceps" => 0.5},
    "lower arms" => %{"forearm" => 1.0},
    "waist" => %{"abs" => 0.7, "obliques" => 0.3},
    "upper legs" => %{"quadriceps" => 0.4, "hamstring" => 0.35, "gluteal" => 0.25},
    "lower legs" => %{"calves" => 0.8, "tibialis" => 0.2},
    "neck" => %{"trapezius" => 1.0},
    "full body" => %{
      "chest" => 0.2,
      "upper-back" => 0.2,
      "gluteal" => 0.2,
      "quadriceps" => 0.2,
      "hamstring" => 0.1,
      "abs" => 0.1
    },
    "cardio" => %{}
  }

  def routine_load(state, routine) do
    Enum.reduce(routine["ex"], %{}, fn config, load ->
      exercise =
        Enum.find(state["customEx"], &(&1["id"] == config["id"])) || Catalogue.get(config["id"]) ||
          config

      sets = max(1, integer(config["sets"], 1))

      Enum.reduce(muscles_of(exercise), load, fn {muscle, weight}, totals ->
        Map.update(totals, muscle, weight * sets, &(&1 + weight * sets))
      end)
    end)
  end

  def ranked(load) do
    @muscles
    |> Enum.filter(&(Map.get(load, &1, 0) > 0))
    |> Enum.sort_by(
      &{-Map.get(load, &1, 0), Enum.find_index(@muscles, fn item -> item == &1 end)}
    )
  end

  def muscle_name(slug), do: Map.get(@names, slug, slug)

  def views(body, load) do
    geometry = Map.get(@geometry, to_string(body), @geometry["male"])
    levels = levels(load)

    Enum.map(~w(front back), fn side ->
      view = geometry[side]

      inert_paths =
        Enum.flat_map(@inert, fn muscle ->
          Enum.map(view["p"][muscle] || [], &%{d: &1, class: "bm-sil", title: nil})
        end)

      muscle_paths =
        Enum.flat_map(@muscles, fn muscle ->
          Enum.map(
            view["p"][muscle] || [],
            &%{
              d: &1,
              class: "bm-m l#{Map.get(levels, muscle, 0)}",
              title: muscle_name(muscle)
            }
          )
        end)

      %{view_box: view["vb"], paths: inert_paths ++ muscle_paths}
    end)
  end

  defp levels(load) do
    maximum = @muscles |> Enum.map(&Map.get(load, &1, 0)) |> Enum.max(fn -> 0 end)

    Map.new(@muscles, fn muscle ->
      value = Map.get(load, muscle, 0)

      level =
        if value <= 0 || maximum <= 0,
          do: 0,
          else: (value / maximum * 4) |> Float.ceil() |> trunc() |> min(4)

      {muscle, level}
    end)
  end

  defp muscles_of(exercise) do
    weights = %{}
    weights = add_muscle(weights, exercise["tg"], 1.0)
    weights = add_muscle(weights, exercise["mg"], 0.4)
    weights = Enum.reduce(List.wrap(exercise["sm"]), weights, &add_muscle(&2, &1, 0.4))

    if map_size(weights) == 0,
      do: Map.get(@body_parts, exercise["bp"], %{}),
      else: weights
  end

  defp add_muscle(weights, value, weight) do
    case Map.get(@aliases, value |> to_string() |> String.downcase() |> String.trim()) do
      nil -> weights
      muscle -> Map.update(weights, muscle, weight, &max(&1, weight))
    end
  end

  defp integer(value, fallback) do
    case Integer.parse(to_string(value)) do
      {number, _rest} -> number
      :error -> fallback
    end
  end
end
