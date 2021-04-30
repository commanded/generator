defmodule Commanded.Generator.Model.Event do
  alias Commanded.Generator.Model.Field
  alias __MODULE__

  @type t :: %Event{
          id: String.t(),
          name: String.t(),
          module: atom(),
          fields: list(Field.t())
        }

  defstruct [:id, :name, :module, fields: []]
end
