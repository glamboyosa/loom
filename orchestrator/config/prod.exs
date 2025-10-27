import Config

# Configure your database
config :orchestrator, Orchestrator.Repo,
  database: Path.expand("../loom.db", __DIR__),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# The secret key base is used to sign/encrypt cookies and other secrets.
# A default value is used in config/dev.exs and config/test.exs but you
# want to use a different value for prod and you most likely don't want
# to check this value into version control, so we use an environment
# variable instead.
secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :orchestrator, OrchestratorWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "localhost", port: 4000],
  http: [
    ip: {0, 0, 0, 0, 0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  secret_key_base: secret_key_base

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to your endpoint configuration:
#
#     config :orchestrator, OrchestratorWeb.Endpoint,
#       https: [
#         ...,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :orchestrator, OrchestratorWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :orchestrator, OrchestratorWeb.Endpoint, server: true
#
# Note you can't rely on `System.get_env/1` when using releases.
# See the releases documentation for more information.

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
