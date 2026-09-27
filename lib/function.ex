defmodule M do
  def main do
    data_stuff()
  end

  def data_stuff do
    my_int = 123
    IO.puts("Integer #{is_integer(my_int)}")
  end
end
