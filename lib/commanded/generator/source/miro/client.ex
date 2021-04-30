defmodule Commanded.Generator.Source.Miro.Client do
  def new(opts \\ []) do
    access_token = Keyword.get(opts, :access_token) || System.get_env("MIRO_ACCESS_TOKEN")

    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.miro.com/v1"},
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{access_token}"}]},
      {Tesla.Middleware.Compression, format: "gzip"},
      Tesla.Middleware.JSON
      # Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  @doc """
  List all widgets.

  `GET https://api.miro.com/v1/boards/{id}/widgets/`

  """
  def list_all_widgets(client, board_id, query \\ []) do
    case Tesla.get(client, "/boards/" <> board_id <> "/widgets/", query: query) do
      {:ok, %Tesla.Env{status: 200, body: %{"type" => "collection", "data" => data}}} ->
        {:ok, data}

      {:ok, %Tesla.Env{body: %{"message" => message}}} ->
        {:error, message}

      {:ok, %Tesla.Env{} = env} ->
        {:error, env}

      reply ->
        reply
    end
  end
end
