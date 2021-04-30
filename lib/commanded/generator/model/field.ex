defmodule Commanded.Generator.Model.Field do
  alias __MODULE__

  @type t :: %Field{
          name: String.t(),
          field: atom()
        }

  defstruct [:name, :field]
end
