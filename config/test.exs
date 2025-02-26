import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :work_hive, WorkHiveWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "rh8cD9Qz1SHGs+D3QOJGRCXP1z0WfCquDJCgaaH/U0RrMjojZQcmuEWbi1vnzkRp",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
