require "pliny/config_helpers"

# Access all config keys like the following:
#
#     Config.database_url
#
# Each accessor corresponds directly to an ENV key, which has the same name
# except upcased, i.e. `DATABASE_URL`.
module Config
  extend Pliny::CastingConfigHelpers

  # Mandatory -- exception is raised for these variables when missing.
  mandatory :api_key_hmac_secret
  mandatory :database_url
  mandatory :heroku_api_url
  mandatory :mailgun_smtp_login
  mandatory :mailgun_smtp_password
  mandatory :mailgun_smtp_port, int
  mandatory :mailgun_smtp_server

  # Optional -- value is returned or `nil` if it wasn't present.
  optional :additional_api_headers
  optional :deployment
  optional :console_banner
  optional :versioning_app_name
  optional :versioning_default
  optional :database_log_level

  # Override -- value is returned or the set default
  override :cache_user_auth, true, bool
  override :database_timeout, 10, int
  override :db_pool, 5, int
  override :force_ssl, true, bool
  override :metric_source, "telex.local", string
  override :port, 5000, int
  override :pretty_json, false, bool
  override :puma_max_threads, 16, int
  override :puma_min_threads, 1, int
  override :puma_workers, 3, int
  override :rack_env, "development", string
  override :raise_errors, false, bool
  override :root, File.expand_path("../../", __FILE__), string
  override :timeout, 45, int
  override :versioning, false, bool
  override :users_endpoint_authorized_producers, "", array
end
