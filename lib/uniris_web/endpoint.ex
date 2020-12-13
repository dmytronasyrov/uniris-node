defmodule UnirisWeb.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :uniris
  use Absinthe.Phoenix.Endpoint

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_uniris_key",
    signing_salt: "wwLmAJji"
  ]

  socket("/socket", UnirisWeb.UserSocket,
    websocket: true,
    longpoll: false
  )

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :uniris,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt .well-known)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, {:json, length: 20_000_000}],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(CORSPlug, origin: "*")
  plug(UnirisWeb.Router)

  def init(_key, config) do
    if config[:load_from_system_env] do
      host = System.get_env("HOSTNAME") 
      || raise "expected the HOSTNAME environment variable to be set"

      port = System.get_env("REST_PORT") 
      || raise "expected the REST_PORT environment variable to be set"

      port =
        port
        |> String.to_integer()

      tls_port =
        System.get_env("REST_TLS_PORT") ||
          raise("expected the REST_TLS_PORT environment variable to be set")

      tls_port =
        tls_port
        |> String.to_integer()

      tls_key =
        System.get_env("UNIRIS_WEB_SSL_KEY_PATH") ||
          raise("expected the UNIRIS_WEB_SSL_KEY_PATH environment variable to be set")

      tls_cert =
        System.get_env("UNIRIS_WEB_SSL_CERT_PATH") ||
          raise("expected the UNIRIS_WEB_SSL_CERT_PATH environment variable to be set")

      config =
        config
        |> Keyword.put(:http, port: port)
        |> Keyword.put(:url,
          host: host,
          port: tls_port
        )
        |> Keyword.put(:https,
          port: tls_port,
          keyfile: tls_key,
          certfile: tls_cert
        )

      {:ok, config}
    else
      {:ok, config}
    end
  end
end
