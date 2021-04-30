import Config

config :<%= @app_name %>, <%= @app_module %>.EventStore,
  username: "postgres",
  password: "postgres",
  database: "<%= @app_name %>_test",
  hostname: "localhost"
