import Config

config :<%= @app_name %>, <%= @app_module %>.EventStore,
  username: "postgres",
  password: "postgres",
  database: "<%= @app_name %>_prod",
  hostname: "localhost"

config :<%= @app_name %>, <%= @app_module %>.Repo,
  username: "postgres",
  password: "postgres",
  database: "<%= @app_name %>_prod",
  hostname: "localhost"
