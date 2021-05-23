import Config

config :<%= @app_name %>,
  ecto_repos: [<%= @app_module %>.Repo],
  event_stores: [<%= @app_module %>.EventStore]

config :<%= @app_name %>, <%= @app_module %>.Repo, migration_source: "ecto_migrations"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
