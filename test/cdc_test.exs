defmodule CDCTest do
  use ExUnit.Case
  doctest CDC

  test "greets the world" do
    assert CDC.hello() == "Hello, world!"
  end
end
