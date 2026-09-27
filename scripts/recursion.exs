a_list = ["My", "random", "words"]
b_list = [1, 2, 3]

defmodule M do
  def display_list([word | words]) do
    IO.puts(word)
    display_list(words)
  end

  def display_list([]), do: nil

  def sum([]), do: 0
  def sum([h | t]), do: h + sum(t)
end

M.display_list(a_list)
IO.puts(M.sum(b_list))
