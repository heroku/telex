web: bin/puma --config config/puma.rb config.ru
worker: bin/sidekiq --tag=${DYNO:-default} --queue=default,2 --queue=rollbar,1 -r ./lib/application.rb 
clock: bin/clockwork lib/clock.rb
# Customize the `heroku console` experience
console: bin/console
