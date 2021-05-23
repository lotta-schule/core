import Config

# gitlab-runner k8s executor does not resolve hosts
db_host =
  case System.get_env("CI") do
    nil -> "postgres"
    _ -> "127.0.0.1"
  end

rabbitmq_host =
  case System.get_env("CI") do
    nil -> "rabbitmq"
    _ -> "127.0.0.1"
  end

redis_host =
  case System.get_env("CI") do
    nil -> "redis"
    _ -> "127.0.0.1"
  end

elasticsearch_host =
  case System.get_env("CI") do
    nil -> "elasticsearch"
    _ -> "127.0.0.1"
  end

minio_host =
  case System.get_env("CI") do
    nil -> "minio"
    _ -> "127.0.0.1"
  end

db_host = "postgres"
rabbitmq_host = "rabbitmq"
redis_host = "redis"
elasticsearch_host = "elasticsearch"
minio_host = "minio"

config :api, :environment, :test

# Configure your database
config :api, Api.Repo,
  username: "lotta",
  password: "lotta",
  database: "api_test",
  hostname: db_host,
  prefix: "public",
  after_connect: {Api.Repo, :after_connect, ["public"]},
  ownership_timeout: 60_000,
  timeout: 60_000,
  pool: Ecto.Adapters.SQL.Sandbox

config :api, :default_configuration, %{
  slug: "web",
  title: "Web Beispiel",
  custom_theme: %{}
}

config :api, :rabbitmq,
  url: "amqp://guest:guest@#{rabbitmq_host}",
  prefix: "test"

config :api, :redis_connection,
  host: redis_host,
  password: "lotta",
  name: :redix,
  timeout: 15000

config :api, Api.Mailer, adapter: Bamboo.TestAdapter

config :ex_aws, :hackney_opts,
  follow_redirect: true,
  recv_timeout: 45_000

config :api, ApiWeb.Auth.AccessToken,
  issuer: "lotta",
  secret_key: "JM1gXuiWLLO766ayWjaee4Ed/8nmwssLoDbmtt0+yct7jO8TmFsCeOQhDcqQ+v2D"

config :api, Api.Elasticsearch.Cluster, url: "http://#{elasticsearch_host}:9200"

config :ex_aws, :s3,
  http_client: ExAws.Request.Hackney,
  access_key_id: "AKIAIOSFODNN7EXAMPLE",
  secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  host: minio_host,
  scheme: "http://",
  port: 9000

config :api, Api.Storage.RemoteStorage,
  default_storage: "minio",
  prefix: "test",
  storages: %{
    "minio" => %{
      type: Api.Storage.RemoteStorage.Strategy.S3,
      config: %{
        endpoint: "http://minio:9000",
        bucket: "lotta-dev-ugc"
      }
    }
  }

config :api, :hostname, "lotta.web"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :api, ApiWeb.Endpoint,
  http: [port: 4002],
  server: false

config :junit_formatter,
  print_report_file: true,
  include_filename?: true,
  include_file_line?: true

# Print only warnings and errors during test
config :logger, level: :warn
