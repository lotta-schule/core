defmodule Api.EmailPublisherWorker do
  use GenServer
  use AMQP
  alias Api.Services.EmailSendRequest
  alias Api.Tenants.Tenant

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: :email_publisher)
  end

  @exchange    "email"
  @queue       "email-out-queue"

  def init(_opts) do
    {:ok, conn} = open_connection()
    {:ok, chan} = Channel.open(conn)
    setup_queue(chan)

    {:ok, chan}
  end

  defp open_connection() do
    config = Application.fetch_env!(:api, :rabbitmq_connection)
    Connection.open(
      username: Keyword.get(config, :username),
      password: Keyword.get(config, :password),
      host: Keyword.get(config, :host)
    )
  end

  def send_email(%EmailSendRequest{} = email_send_request) do
    IO.inspect(email_send_request)
    {:ok, email_send_request} = Poison.encode(email_send_request)
    publish(email_send_request)
    email_send_request
  end

  def send_registration_email(%Tenant{} = tenant, %Api.Accounts.User{} = user) do
    Api.EmailPublisherWorker.send_email(%EmailSendRequest{
      to: user.email,
      subject: "Deine Registrierung bei #{tenant.title}",
      template: "default",
      templatevars: %{
        tenant: EmailSendRequest.get_tenant_info(tenant),
        heading: "Deine Registrierung bei #{tenant.title}",
        content: "Hallo #{user.name},<br />Du wurdest erfolgreich registriert.<br />" <>
          "Du kannst nun Beiträge erstellen.<br /> <br />"
      }
    })
  end

  def send_request_password_reset_email(%Tenant{} = tenant, %Api.Accounts.User{} = user, email, token) do
    url =
      %{ e: Base.encode64(email), t: token }
      |> URI.encode_query
      |> String.replace_prefix("", "#{Tenant.get_main_url(tenant)}/password/reset?")

    Api.EmailPublisherWorker.send_email(%EmailSendRequest{
      to: email,
      sender_name: tenant.title,
      subject: "Passwort zurücksetzen",
      template: "default",
      templatevars: %{
        tenant: EmailSendRequest.get_tenant_info(tenant),
        heading: "Setz dein Passwort zurück",
        content: "Hallo #{user.name},<br />über die Seite #{Tenant.get_main_url(tenant)} wurde eine Anfrage zum zurücksetzen deines Passworts gesendet.<br />" <>
          "Dein Passwort kannst du über folgenden Link zurücksetzen: <a href='#{url}'>#{url}</a>.<br /><br />" <>
          "Solltest du die Anfrage nicht selbst versandt haben, kannst du diese Nachricht ignorieren."
      }
    })
  end

  def send_password_changed_email(%Tenant{} = tenant, %Api.Accounts.User{} = user) do
    Api.EmailPublisherWorker.send_email(%EmailSendRequest{
      to: user.email,
      sender_name: tenant.title,
      subject: "Dein Passwort wurde geändert",
      template: "default",
      templatevars: %{
        tenant: EmailSendRequest.get_tenant_info(tenant),
        heading: "Dein Passwort",
        content: "Hallo #{user.name},<br />Dein Passwort wurde über die Seite #{Tenant.get_main_url(tenant)} erfolgreich geändert.<br />"
      }
    })
  end

  def publish(message) do
    GenServer.cast(:email_publisher, {:publish, message})
  end

   def handle_cast({:publish, message}, channel) do
    IO.inspect(channel)
    AMQP.Basic.publish(channel, @exchange, @queue, message, persistent: true)
    {:noreply, channel}
  end

  defp setup_queue(chan) do
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    {:ok, _} = Queue.declare(chan, @queue, durable: true)
    :ok = Exchange.fanout(chan, @exchange, durable: true)
    :ok = Queue.bind(chan, @queue, @exchange)
  end

end