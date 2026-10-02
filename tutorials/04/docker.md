# DOCKER IN 45 MINUTES

Credits: this tutorial was created by [Valerio Schiavoni](http://members.unine.ch/valerio.schiavoni/)

A cross-platform hands-on tutorial for MSc Computer Science students

- Audience: Students comfortable with a terminal and basic programming
- Duration: 45 minutes
- Platforms: Windows 10/11, macOS, Linux
- Container mode: Linux containers

## LEARNING GOALS
By the end, you should be able to:
- Explain the difference between an image and a running container.
- Build an image from a Dockerfile and run it as a container.
- Publish a container port to the host and inspect container logs.
- Run two Elixir nodes in a Docker network and make a remote procedure call.
- Explain why a regular container is not, by itself, a strong confidentiality boundary.

## WHAT YOU NEED BEFORE CLASS
- A laptop with Docker available and enough disk space to pull a small base image.
- Windows: Docker Desktop configured to use Linux containers, usually through WSL 2.
- macOS: Docker Desktop.
- Linux: Docker Engine and the Docker CLI, or Docker Desktop.
- A text editor. Use plain text; save the files with the exact names shown below.
- Internet access the first time the base image is pulled.

To keep the practical within 45 minutes, the instructor should pre-pull both base images:

    docker pull python:3.12-slim
    docker pull elixir:1.20.4-alpine

The Docker daemon must be running. Verify in a terminal or PowerShell:

    docker version
    docker run --rm hello-world

If `docker version` shows only a Client section, start Docker Desktop or the Docker Engine service. If the second command cannot connect, resolve that before continuing. On Linux, do not automatically add yourself to the `docker` group on a shared or security-sensitive machine: access to the Docker daemon is highly privileged. Ask the instructor or administrator for the approved setup.

## TENTATIVE SCHEDULE: 45-MINUTE 

| Time      | Activity                                                                  |
|-----------|---------------------------------------------------------------------------|
| 0–5 min   | Check Docker is installed and running; discuss image vs. container.       |
| 5–10 min  | Create the two project files.                                             |
| 10–18 min | Build the image and run the application.                                  |
| 18–25 min | Test the published port; inspect logs and container state.                |
| 25–40 min | Run a two-node Elixir distributed-systems example.                        |
| 40–45 min | Discuss isolation limits and connect the exercise to confidential containers. |

## PART 1 - A SMALL WEB SERVICE (5-10 MIN)

Create a folder named `docker-lab` and open a terminal in that folder. The commands below are the same in PowerShell, Windows Terminal, macOS Terminal, and a Linux shell.

    mkdir docker-lab
    cd docker-lab

Create a file named `app.py` with this content:

```python
from http.server import BaseHTTPRequestHandler, HTTPServer
from html import escape
import os
import socket

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        course = escape(os.getenv("COURSE", "Docker lab"))
        container = escape(socket.gethostname())
        body = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Docker lab</title></head>
<body><h1>Hello from a container</h1>
<p>Course: {course}</p><p>Container hostname: {container}</p></body></html>""".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
```

Create a file named `Dockerfile` (capital D, no extension):

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py /app/app.py
EXPOSE 8000
USER 10001:10001
CMD ["python", "app.py"]
```

### DISCUSSION
- The image contains a base filesystem plus the app and its startup command.
- The container is a process created from that image, with runtime configuration.
- `EXPOSE` documents the app's listening port. It does not publish the port to the host.
- `USER` avoids running the application as root inside the container.


## PART 2 - BUILD AND RUN 

Build an image. Include the period at the end; it means “use this directory as the build context.”

    docker build -t uni-ne-docker-lab:1.0 .

Run it in the background and map host port 8080 to container port 8000:

    docker run --rm -d --name web-lab -p 8080:8000 -e COURSE="Concurrent and Distributed Computing" uni-ne-docker-lab:1.0

Open this address in a browser:

    http://localhost:8080

Expected result: a page showing “Hello from a container”, the course name, and a container hostname. The application listens on port 8000 inside the container; `-p 8080:8000` makes it reachable as port 8080 on the host.

If port 8080 is already in use, stop the container and retry with another host port, for example `-p 8081:8000`; then open `http://localhost:8081`.

## PART 3 - OBSERVE THE CONTAINER

Run these commands and discuss what each reveals:

    docker ps
    docker logs web-lab
    docker inspect web-lab

`docker ps` lists running containers. `docker logs` shows output written by the process. `docker inspect` returns detailed configuration and runtime state; it is JSON and can be long.

Stop the container:

    docker stop web-lab

Because it was started with `--rm`, Docker removes the stopped container. The image remains. Confirm:

    docker ps -a
    docker images

Run it again with a different name and host port:

    docker run --rm -d --name web-lab-2 -p 8081:8000 -e COURSE="Concurrent and Distributed Computing" uni-ne-docker-lab:1.0

Visit `http://localhost:8081`, then stop it:

    docker stop web-lab-2

## PART 4 - TWO ELIXIR NODES AND A REMOTE CALL 

This example uses Erlang distribution through Elixir: one BEAM node waits as a worker; a second node connects to it and asks it to report its node name using RPC. Both nodes run in one user-defined Docker network. This is a teaching demo, not a production cluster.

From the parent folder containing `docker-lab`, create and enter a new folder:

    cd ..
    mkdir elixir-demo
    cd elixir-demo

Create `node.exs`:

```elixir
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
```

Create a `Dockerfile`:

```dockerfile
FROM elixir:1.20.4-alpine
WORKDIR /app
COPY node.exs /app/node.exs
ENTRYPOINT ["elixir"]
CMD ["--sname", "worker", "--cookie", "labcookie", "/app/node.exs", "worker"]
```

Build the image:

    docker build -t ds-elixir-demo:1.0 .

Create a user-defined Docker network for the two containers:

    docker network create ds-net

Start the worker. It uses a fixed Erlang distribution port so the example is easier to reason about. No port is published to the host; the nodes communicate over `ds-net`.

    docker run --rm -d --name elixir-worker --hostname elixir-worker --network ds-net -e ERL_AFLAGS="-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9100" ds-elixir-demo:1.0

Check that the worker node started:

    docker logs elixir-worker

Run the client node. The arguments after the image override the default worker command:

    docker run --rm --name elixir-client --hostname elixir-client --network ds-net -e ERL_AFLAGS="-kernel inet_dist_listen_min 9100 inet_dist_listen_max 9100" ds-elixir-demo:1.0 --sname client --cookie labcookie /app/node.exs client

Expected output includes `true` for the connection and `:"worker@elixir-worker"` as the RPC result. The RPC invokes `:erlang.node/0` on the worker node, so the client receives the worker's node identity rather than its own.

Stop the worker and remove the network:

    docker stop elixir-worker
    docker network rm ds-net

## DISCUSSION
- Containers can resolve each other by name on a user-defined Docker network.
- Erlang distribution needs reachable nodes, matching cookies, and distribution ports. This demo fixes the distribution port at 9100; EPMD discovery uses port 4369 inside the Docker network.
- The cookie is a shared secret. `labcookie` is intentionally weak and must never be reused outside this isolated classroom exercise. Erlang distribution should not be exposed to untrusted networks.
- This demonstrates a remote node call; it does not provide fault tolerance, service discovery, encryption, or production security.

## OPTIONAL CHALLENGE (IF YOU FINISHES EARLY)

1. Start two containers from the same image, using different host ports and `COURSE` values. Are the containers using one image or two?
2. Try publishing a second host port while container port 8000 remains unchanged.
3. What changes if you omit `-p 8080:8000`? Is the service reachable from the host browser?
4. Add a `HEALTHCHECK` to the Dockerfile. What does it tell you, and what does it not prove?
5. Find the image ID and compare it with the tag. Which is the more stable identifier?
6. From `elixir-demo`, run `cd ..` and then `cd docker-lab`. Change the web page heading, rebuild it as `uni-ne-docker-lab:2.0`, and start a new container. Explain why the already running container does not change when a new image is built.
7. Change the Elixir cookie on only one node. What happens to `Node.connect/1`? Restore the classroom cookie after observing the failure.


## DISCUSSION QUESTIONS
- Which parts of the system were isolated in this lab, and which kernel was shared?
- What does publishing a port expose? What changes if the service binds to `0.0.0.0` inside the container?
- Why are bind mounts, privileged mode, and access to the Docker daemon security-sensitive?

## CLEANUP

    docker ps
    docker stop web-lab web-lab-2 web-lab-locked elixir-worker

Some stop commands may report that a named container does not exist; that is fine if you did not run that version. To remove the lab images after class:

    docker image rm uni-ne-docker-lab:1.0 uni-ne-docker-lab:2.0 ds-elixir-demo:1.0

To remove the folder, use your file manager. This avoids shell-specific recursive-delete commands.

## TROUBLESHOOTING

- “Cannot connect to the Docker daemon”: start Docker Desktop / Docker Engine, then retry `docker version`.
- “Bind for 0.0.0.0:8080 failed”: choose a different host port such as 8081 in both `-p` and the browser URL.
- Browser cannot connect: check `docker ps`, confirm the mapping is `0.0.0.0:8080->8000/tcp`, and check `docker logs web-lab`.
- Build cannot find Dockerfile: check the current directory and that the filename is exactly `Dockerfile`, without `.txt`.
- Python syntax error: ensure `app.py` uses plain text and that indentation is preserved.
- Elixir client cannot connect: check `docker logs elixir-worker`, verify both containers joined `ds-net`, and confirm node names, the shared cookie, and `ERL_AFLAGS` match exactly.
- Docker reports that `ds-net` already exists: remove the leftover network with `docker network rm ds-net`, then create it again.
- Windows using Windows containers: switch Docker Desktop to Linux containers. This exercise uses a Linux base image.
- Windows using WSL 2: run the Docker CLI in PowerShell or a WSL terminal connected to Docker Desktop's engine; use the same commands either way.

## FURTHER READING

- Docker documentation: https://docs.docker.com/get-started/
- Docker Engine security: https://docs.docker.com/engine/security/
- Elixir official Docker image: https://hub.docker.com/_/elixir
- Elixir and distributed nodes: https://elixir-lang.org/blog/2025/08/18/interop-and-portability/

