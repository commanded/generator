defmodule Commanded.Generator.Model.Command do
  alias __MODULE__

  @type t :: %Command{
          name: String.t(),
          module: atom()
        }

  defstruct [:name, :module]
end
