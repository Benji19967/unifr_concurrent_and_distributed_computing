defmodule M do
  def main do
    do_stuff()
  end

  def do_stuff do
    capitals = %{
      "Switzerland" => "Bern",
      "France" => "Paris"
    }

    capitals2 = %{
      switzerland: "Bern",
      france: "Paris"
    }

    capitals3 = Map.put_new(capitals2, :norway, "Oslo")

    IO.puts(capitals["France"])
    IO.puts(capitals2.switzerland)
    IO.puts(capitals3.norway)
  end
end

M.main()
