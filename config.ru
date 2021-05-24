require_relative "lib/application"

$stdout.sync = (Config.deployment != "production")

run Routes
