defmodule DespegarAppTest do
  use ExUnit.Case
  doctest DespegarApp

  test "greets the world" do
    assert DespegarApp.hello() == :world
  end
end
