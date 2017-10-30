# Code::Stats

[![Join the chat at https://gitter.im/code-stats/Lobby](https://badges.gitter.im/code-stats/Lobby.svg)](https://gitter.im/code-stats/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Code::Stats is a free stats tracking service for programmers: [https://codestats.net/](https://codestats.net/).

This repository contains the Phoenix application that implements the service backend.

## Installation for development

### Requirements

These are my targets, older versions _might_ work:

* Erlang 20.0+
* Elixir 1.5+
* PostgreSQL 9.6+
* Node 8+ and NPM

### First time install

```
mix deps.get                # Get Hex dependencies, answer yes to installing Hex/rebar if
                            # needed
mix compile                 # Compile application
mix ecto.create             # Create database using default credentials
mix ecto.migrate            # Migrate database to latest state
cd assets && npm install    # Install frontend dependencies and tools
nano config/dev.secret.exs  # Set up dev config with at least the line "use Mix.Config"
                            # at the top
```

### Commands

* `mix phoenix.server`: Run development server on port 15000 (host, inside Vagrant port is 5000)
* `mix frontend.build`: Build the JS/CSS frontend
* `mix frontend.watch`: Build the frontend and watch for changes (also run when using `phoenix.server`)
* `mix frontend.clean`: Clean frontend output and build artifacts
* `MINIFY=true mix frontend.build`: Build frontend with minification.

Ready to run in production? Please [check the Phoenix deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more about Phoenix

* Official website: http://www.phoenixframework.org/
* Guides: http://phoenixframework.org/docs/overview
* Docs: http://hexdocs.pm/phoenix
* Mailing list: http://groups.google.com/group/phoenix-talk
* Source: https://github.com/phoenixframework/phoenix
