defmodule <%= @app_module %>.App do
  @moduledoc false

  use Commanded.Application,
    otp_app: :<%= @app_name %>,
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: <%= @app_module %>.EventStore
    ]

  router(<%= @app_module %>.Router)
end
