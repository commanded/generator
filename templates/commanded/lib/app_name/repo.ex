defmodule <%= @app_module %>.Repo do
  use Ecto.Repo,
    otp_app: :<%= @app_name %>,
    adapter: Ecto.Adapters.Postgres

  # Optional `init/2` function to modify config at runtime.
  def init(_type, config) do
    {:ok, config}
  end
end
