defmodule ApiWeb.Endpoint do
  @moduledoc """
  Phoenix endpoint configuration
  """

  use Phoenix.Endpoint, otp_app: :api

  socket "/socket", ApiWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :api,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    # 1.5 GB
    length: 1.5 * 1024 * 1024 * 1024,
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Corsica,
    max_age: 7200,
    origins: {ApiWeb.Cors, :allow_origin},
    allow_headers: [
      "Authorization",
      "Tenant",
      "Content-Type",
      "Accept",
      "Origin",
      "User-Agent",
      "DNT",
      "Cache-Control",
      "X-Mx-ReqToken",
      "Keep-Alive",
      "X-Requested-With",
      "If-Modified-Since",
      "X-CSRF-Token"
    ],
    allow_credentials: true

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_api_key",
    signing_salt: "sPyTc4VZ"

  plug ApiWeb.Router

  socket "/live", Phoenix.LiveView.Socket
end
