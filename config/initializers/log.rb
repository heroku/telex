Pliny.default_context = {app: "telex", deploy: Config.deployment, source: Config.metric_source}

Pliny.log_scrubber = BlacklistHash.build(fields_to_scrub: Rollbar::Blanket.fields, scrub_urls: true)
