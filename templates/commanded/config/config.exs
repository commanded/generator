import Config

config :<%= @app_name %>, event_stores: [<%= @app_module %>.EventStore]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
