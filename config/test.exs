use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hangman, HangmanWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :hangman, Hangman.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "root",
  database: "hangman_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
