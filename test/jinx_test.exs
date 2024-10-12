defmodule JinxTest do
  use ExUnit.Case

  doctest Jinx

  test "greets the world" do
    assert Jinx.hello() == :world
  end
end
