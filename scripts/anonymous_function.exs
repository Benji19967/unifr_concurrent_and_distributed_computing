defmodule M do
  def main do
    get_sum = fn x, y -> x + y end
    get_mult = &(&1 * &2)

    add_sum = fn
      {x, y} -> x + y
      {x, y, z} -> x + y + z
    end

    IO.puts(get_sum.(1, 2))
    IO.puts(get_mult.(3, 2))
    IO.puts(add_sum.({5, 2}))
    IO.puts(add_sum.({5, 2, 3}))
    IO.puts(default_vals())
  end

  def default_vals(x \\ 8, y \\ 9) do
    x + y
  end
end

M.main()
