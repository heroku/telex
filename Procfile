web: bundle exec puma --config config/puma.rb config.ru
worker: bundle exec sidekiq -g ${DYNO:-default} -i ${DYNO:-1} -r ./lib/application.rb
clock: bundle exec clockwork lib/clock.rb
# Customize the `heroku console` experience
console: bin/console
