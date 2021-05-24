Mail.defaults do
  delivery_method :smtp, {
    address: Config.mailgun_smtp_server,
    port: Config.mailgun_smtp_port,
    user_name: Config.mailgun_smtp_login,
    password: Config.mailgun_smtp_password,
    authentication: :plain,
    enable_starttls_auto: true
  }
end
