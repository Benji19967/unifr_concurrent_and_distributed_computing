a_list = ["My", "random", "words"]

defmodule M do
  def display_list([word | words]) do
    IO.puts(word)
    display_list(words)
  end

  def display_list([]), do: nil
end

M.display_list(a_list)
