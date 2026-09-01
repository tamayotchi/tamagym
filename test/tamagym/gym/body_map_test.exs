defmodule Tamagym.Gym.BodyMapTest do
  use ExUnit.Case, async: true

  alias Tamagym.Gym.{BodyMap, State}

  test "routine load drives ranked muscles and highlighted body paths" do
    routine = %{"ex" => [%{"id" => "0001", "sets" => 3}]}
    load = BodyMap.routine_load(State.defaults(), routine)

    assert load["abs"] == 3.0
    assert_in_delta load["hip-flexors"], 1.2, 0.001
    assert_in_delta load["lower-back"], 1.2, 0.001
    assert List.first(BodyMap.ranked(load)) == "abs"

    views = BodyMap.views("male", load)
    assert length(views) == 2
    assert Enum.all?(views, &(&1.paths != []))

    assert Enum.any?(views, fn view ->
             Enum.any?(view.paths, &(&1.title == "Abs" && &1.class == "bm-m l4"))
           end)
  end
end
