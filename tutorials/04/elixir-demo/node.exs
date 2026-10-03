case System.argv() do
  ["worker"] ->
    IO.puts("Worker node ready as #{Node.self()}")
    Process.sleep(:infinity)

  ["client"] ->
    target = :"worker@elixir-worker"
    IO.puts("Client node is #{Node.self()}")

    case Node.connect(target) do
      true ->
        result = :rpc.call(target, :erlang, :node, [])
        IO.inspect(result, label: "RPC returned remote node")

      false ->
        raise "Could not connect to #{target}; check the worker, network, and cookie"
    end

  other ->
    raise "Expected worker or client argument, received: #{inspect(other)}"
end
