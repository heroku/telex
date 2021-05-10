# 𝕋𝔼𝕃𝔼𝕏

[![Build Status](https://circleci.com/gh/heroku/telex.svg?style=svg)](https://circleci.com/gh/heroku/telex)
[![Maintainability](https://api.codeclimate.com/v1/badges/f23b929ebd51edf45dfd/maintainability)](https://codeclimate.com/repos/53ebf597e30ba01158015b7a/maintainability)

![telex](docs/telex-cc-by-sa-jens-ohlig.jpg)

## Overview

To send messages through telex, you'll first need a `Producer`. A Producer is like an "Application Authorization", with a name and credentials. It can represent a component, team, person, etc that wants to send notifications to customers - or you can use a different one for each type of message you send.

Using your Producer credentials, you can send a `Message` to 𝕋𝔼𝕃𝔼𝕏 through the API directly, or using a client such as [minitel](https://github.com/heroku/minitel).

A Message can target either an App or a User. If it's a user, it just looks up the user. If it is an app, 𝕋𝔼𝕃𝔼𝕏 looks up the owner and all collaborators and sends to each of those, without going through [premiumrush](https://github.com/heroku/premiumrush).

A Message has a `title` and a `body`. The body can have access to some variables such as `{{user}}` and `{{app}}`. It inserts these using a simple find-and-replace.

A Message can also be sent as a `followup` to an existing message, threading them in some places.

Both of these always happen, with the same message in both places:
- An email is sent to the user.
- The notification shows up in Dashboard, using the telex endpoint `/user/notifications/`. This endpoint returns the most recent month's  Notifications.

Each message plexed to potentially several `Notifications` for each user. Telex does not de-dupe messages well.

Telex tracks which messages are read, in two ways:
- Emails contain a tracking pixel, like `<img src="https://telex.heroku.com/user/notifications/99d0ee9a-99c9-49b3-95dc-e046a8a1580c/read.png" height="1" width="1">`. Users who don't block image loading will have them marked as read here.
- In Dashboard, users can click "mark all as read" to mark them as read.

## Example Usage

- [Logdrain Remediations](https://github.com/heroku/logdrain-remediation/blob/2fa6b0af6e8fef568dfddb2b70b5542960cf260a/lib/mediators/notifier.rb#L20-L25)
- [Godzilla](https://github.com/heroku/godzilla)

## Development/Maintenance

Telex is currently in maintenance only mode. Web Services handles maintenance
updates and making sure the system is functioning properly but no new features
are being added.

If you have issues or questions, feel free to use `/pd ping` in `#core-services`
on Slack for assistance.

## Setup

```
$ bin/setup
```

### Running locally

Leverage `heroku local`, or a similar Procfile tool to spin things up:

```shell
heroku local web,worker,clock
```

### Local dev console

```shell
heroku local:run bin/console
```

To deploy to the platform:

```
h addons:create heroku-postgresql:standard-0
h pg:promote <that database>
h addons:create mailgun
h addons:create redisgreen
h addons:create pgbackups:auto-month
h config:add REDIS_PROVIDER=REDISGREEN_URL
h config:set API_KEY_HMAC_SECRET=$(dd if=/dev/urandom bs=127 count=1 2>/dev/null | openssl base64 -A)
h config:set HEROKU_API_URL=https://telex:<key>@api.heroku.com

git push heroku master
heroku run bin/rake db:migrate
```

## Operations

Refer to [our internal guide on Telex](https://github.com/heroku/engineering-docs/blob/master/components/telex/README.md)

### Dashboards, Errors, etc…

[Heroku Pipeline](https://dashboard.heroku.com/pipelines/fc112685-54b5-4b3d-8e7d-54924fa3af4d) |
[Watchtower Checks](https://watchtower.herokai.com/apps/telex) |
[Continuous Integration](https://circleci.com/gh/heroku/workflows/telex) |
[Errors](https://rollbar.com/Heroku-3/telex/) |
[Code Quality](https://codeclimate.com/repos/53ebf597e30ba01158015b7a) |
Charts: [Prod](https://metrics.librato.com/s/spaces/54073) / [Staging](https://metrics.librato.com/s/spaces/54074) |
[Logs](https://splunk.herokai.com/en-US/app/search/search/?q=search%20index%3Dmain%20app%3Dtelex) |
[Logs](https://splunk.herokai.com/en-US/app/search/search/?q=search%20index%3A%3Amain%20component%3A%3Atelex%20stage%3A%3Aproduction)
[Herokai Dashboards](https://dashboards.herokai.com)
