FROM elixir:1.20.4-alpine
WORKDIR /app
COPY node.exs /app/node.exs
ENTRYPOINT ["elixir"]
CMD ["--sname", "worker", "--cookie", "labcookie", "/app/node.exs", "worker"]
