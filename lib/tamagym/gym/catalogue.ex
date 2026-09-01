defmodule Tamagym.Gym.Catalogue do
  @moduledoc "The built-in English exercise catalogue used by the LiveView library."

  @external_resource Path.expand("../../../priv/catalogue/exercises.json", __DIR__)
  @exercises @external_resource |> File.read!() |> Jason.decode!()
  @index Map.new(@exercises, &{&1["id"], &1})

  def all, do: @exercises
  def get(id), do: Map.get(@index, to_string(id))

  def search(query, limit \\ 60) do
    terms =
      query
      |> to_string()
      |> normalize()
      |> String.split(~r/\s+/, trim: true)

    @exercises
    |> Enum.filter(fn exercise ->
      haystack =
        [
          exercise["n"],
          exercise["bp"],
          exercise["eq"],
          exercise["tg"],
          exercise["mg"] | List.wrap(exercise["sm"])
        ]
        |> Enum.join(" ")
        |> normalize()

      Enum.all?(terms, &String.contains?(haystack, &1))
    end)
    |> Enum.take(limit)
  end

  defp normalize(value) do
    value
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/[^\x00-\x7F]/u, "")
  end
end
