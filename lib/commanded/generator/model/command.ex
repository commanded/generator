defmodule Commanded.Generator.Model.Command do
  alias Commanded.Generator.Model.Field
  alias __MODULE__

  @type t :: %Command{
          id: String.t(),
          name: String.t(),
          module: atom(),
          fields: list(Field.t())
        }

  defstruct [:id, :name, :module, fields: []]
end
