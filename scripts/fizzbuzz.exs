fb = fn a, b, c ->
  case {a, b, c} do
    {0, 0, _} -> "FizzBuzz"
    {0, _, _} -> "Fizz"
    {_, 0, _} -> "Buzz"
    {_, _, c} -> c
  end
end

IO.puts(fb.(0, 0, 9))
IO.puts(fb.(1, 1, 9))
