defmodule Commanded.Generator.Source do
  alias Commanded.Generator.Model.Application

  @callback build(args :: Keyword.t()) :: {:ok, Application.t()} | {:error, term()}
end
