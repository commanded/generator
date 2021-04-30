defmodule <%= @app_module %>.EventStore do
  @moduledoc false

  use EventStore,
    otp_app: :<%= @app_name %>,
    serializer: Commanded.Serialization.JsonSerializer

  # Optional `init/1` function to modify config at runtime.
  def init(config) do
    {:ok, config}
  end
end
