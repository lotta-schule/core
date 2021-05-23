import Config

config :api, :environment, :development

# Configure your database
config :api, Api.Repo,
  username: "lotta",
  password: "lotta",
  database: "lotta",
  hostname: "postgres",
  prefix: "tenant_2",
  after_connect: {Api.Repo, :after_connect, ["tenant_2"]},
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :api, :rabbitmq,
  url: "amqp://guest:guest@rabbitmq",
  prefix: "tenant_2"

config :api, :default_configuration, %{
  slug: "ehrenberg",
  title: "Ehrenberg-Gymnasium-Delitzsch",
  custom_theme: %{}
}

config :api, :redis_connection,
  host: "redis",
  password: "lotta",
  name: :redix

config :api, Api.Elasticsearch.Cluster, index_prefix: "tenant_2"

config :api, Api.Mailer, adapter: Bamboo.LocalAdapter

config :ex_aws, :s3,
  http_client: ExAws.Request.Hackney,
  access_key_id: "AKIAIOSFODNN7EXAMPLE",
  secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  host: "minio",
  scheme: "http://",
  port: 9000

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :api, ApiWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :api, ApiWeb.Auth.AccessToken,
  issuer: "lotta",
  secret_key: "JM1gXuiWLLO766ayWjaee4Ed/8nmwssLoDbmtt0+yct7jO8TmFsCeOQhDcqQ+v2D"

config :api, :hostname, "localhost"

config :api, :schedule_provider_url, "http://schedule_provider:3000"

config :api, Api.Storage.RemoteStorage,
  default_storage: "minio",
  prefix: "tenant_2",
  storages:
    System.get_env("REMOTE_STORAGE_STORES", "")
    |> String.split(",")
    |> Enum.filter(&(String.length(&1) > 0))
    |> Enum.reduce(%{}, fn storage_name, acc ->
      env_name =
        storage_name
        |> String.upcase()
        |> String.replace("-", "_")

      acc
      |> Map.put(storage_name, %{
        type: Api.Storage.RemoteStorage.Strategy.S3,
        config: %{
          endpoint: System.get_env("REMOTE_STORAGE_#{env_name}_ENDPOINT"),
          bucket: System.get_env("REMOTE_STORAGE_#{env_name}_BUCKET")
        }
      })
    end)
    |> Map.merge(%{
      "minio" => %{
        type: Api.Storage.RemoteStorage.Strategy.S3,
        config: %{
          endpoint: "http://minio:9000",
          bucket: "lotta-dev-ugc"
        }
      }
    })

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :absinthe, Absinthe.Logger, pipeline: true

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
