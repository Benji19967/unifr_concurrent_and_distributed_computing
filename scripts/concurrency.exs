defmodule M do
  def main do
    do_stuff()
    do_tasks()
  end

  def do_stuff do
    parent = self()

    spawn(fn ->
      loop(1, 50)
      send(parent, :done)
    end)

    spawn(fn ->
      loop(51, 100)
      send(parent, :done)
    end)

    receive do: (:done -> :ok)
    receive do: (:done -> :ok)
  end

  def do_tasks do
    t1 = Task.async(fn -> loop(100, 150) end)
    t2 = Task.async(fn -> loop(151, 200) end)
    Task.await(t1)
    Task.await(t2)
  end

  def loop(0, _), do: nil

  def loop(min, max) do
    if max < min do
      loop(0, nil)
    else
      IO.puts("Num: #{min}")
      loop(min + 1, max)
    end
  end
end

M.main()
