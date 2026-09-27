defmodule CDC do
  @moduledoc """
  Documentation for `CDC`.
  """

  @doc """
  Prints a greeting and returns it.

  ## Examples

      iex> CDC.hello()
      "Hello, world!"

  """
  def hello do
    greeting = "Hello, world!"
    IO.puts(greeting)
    greeting
  end
end
