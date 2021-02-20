import Config

# general app config
# Token secrets
secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
secret_key_jwt = System.fetch_env!("SECRET_KEY_JWT")
# Live View
secret_signing_salt_live_view = System.fetch_env!("LIVE_VIEW_SALT_SECRET")
live_view_username = System.fetch_env!("LIVE_VIEW_USERNAME")
live_view_password = System.fetch_env!("LIVE_VIEW_PASSWORD")

port = String.to_integer(System.get_env("PORT") || "4000")
# database
db_user = System.fetch_env!("POSTGRES_USER")
db_password = System.fetch_env!("POSTGRES_PASSWORD")
db_host = System.fetch_env!("POSTGRES_HOST")
db_name = System.fetch_env!("POSTGRES_DB")
db_schema = System.fetch_env!("POSTGRES_SCHEMA")
# config
slug = System.fetch_env!("SHORT_TITLE")
title = System.fetch_env!("TITLE")
# redis
redis_host = System.fetch_env!("REDIS_HOST")
redis_password = System.fetch_env!("REDIS_PASSWORD")
# rabbitMQ
rabbitmq_url = System.fetch_env!("RABBITMQ_URL")
rabbitmq_prefix = System.get_env("RABBITMQ_PREFIX")
# elasticsearch
elasticsearch_host = System.fetch_env!("ELASTICSEARCH_HOST")
elasticsearch_index_prefix = System.fetch_env!("ELASTICSEARCH_INDEX_PREFIX")
# S3-compatible block storage for User Generated Content
ugc_s3_compat_endpoint = System.fetch_env!("UGC_S3_COMPAT_ENDPOINT")
ugc_s3_compat_access_key_id = System.fetch_env!("UGC_S3_COMPAT_ACCESS_KEY_ID")
ugc_s3_compat_secret_access_key = System.fetch_env!("UGC_S3_COMPAT_SECRET_ACCESS_KEY")
ugc_s3_compat_bucket = System.fetch_env!("UGC_S3_COMPAT_BUCKET")
ugc_s3_compat_region = System.fetch_env!("UGC_S3_COMPAT_REGION")
ugc_s3_compat_cdn_base_url = System.fetch_env!("UGC_S3_COMPAT_CDN_BASE_URL")
# Mailgun config
mailgun_api_key = System.get_env("MAILGUN_API_KEY")
mailgun_domain = System.get_env("MAILGUN_DOMAIN")
mailer_default_sender = System.get_env("MAILER_DEFAULT_SENDER")
# App base URL
hostname = System.get_env("HOSTNAME") || "#{slug}.lotta.schule"
# Schedule Provider
schedule_provider_url = System.fetch_env!("SCHEDULE_PROVIDER_URL")
# Sentry Error Logging
sentry_dsn = System.get_env("SENTRY_DSN")

sentry_environment =
  System.get_env("SENTRY_ENVIRONMENT") || System.get_env("APP_ENVIRONMENT") || "production"

config :api, Api.Repo,
  username: db_user,
  password: db_password,
  database: db_name,
  hostname: db_host,
  prefix: db_schema,
  after_connect: {Api.Repo, :after_connect, [db_schema]},
  show_sensitive_data_on_connection_error: false,
  pool_size: 10

config :api, :default_configuration, %{
  slug: slug,
  title: title,
  custom_theme: %{}
}

config :api, :rabbitmq,
  url: rabbitmq_url,
  prefix: rabbitmq_prefix

config :api, :redis_connection,
  host: redis_host,
  password: redis_password,
  name: :redix

config :api, :hostname, hostname
config :api, :schedule_provider_url, schedule_provider_url

config :api, :live_view,
  username: live_view_username,
  password: live_view_password

config :api, :default_user, %{
  name: System.get_env("DEFAULT_USER_NAME"),
  email: System.get_env("DEFAULT_USER_EMAIL"),
  hide_full_name: false,
  password: System.get_env("DEFAULT_USER_PASSWORD")
}

config :api, Api.Elasticsearch.Cluster,
  url: elasticsearch_host,
  index_prefix: elasticsearch_index_prefix

config :api, ApiWeb.Endpoint,
  url: [host: hostname],
  http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: secret_key_base,
  live_view: [signing_salt: secret_signing_salt_live_view]

config :api, Api.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: mailgun_api_key,
  domain: mailgun_domain,
  default_sender: mailer_default_sender,
  base_uri: "https://api.eu.mailgun.net/v3"

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
config :api, ApiWeb.Endpoint, server: true

#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

config :api, ApiWeb.Auth.AccessToken, secret_key: secret_key_jwt

config :ex_aws, :s3,
  http_client: ExAws.Request.Hackney,
  access_key_id: ugc_s3_compat_access_key_id,
  secret_access_key: ugc_s3_compat_secret_access_key,
  host: %{ugc_s3_compat_region => ugc_s3_compat_endpoint},
  region: ugc_s3_compat_region,
  scheme: "https://"

config :sentry,
  dsn: sentry_dsn,
  environment_name: sentry_environment || "staging",
  included_environments: ~w(production staging),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  release:
    (case(sentry_environment) do
       "production" ->
         to_string(Application.spec(:my_app, :vsn))

       _ ->
         System.get_env("APP_RELEASE")
     end)

config :lager,
  error_logger_redirect: false,
  handlers: [level: :debug]
