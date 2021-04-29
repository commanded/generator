defmodule Commanded.Generator.Model.Projection do
  alias __MODULE__

  @type t :: %Projection{
          name: String.t(),
          module: atom()
        }

  defstruct [:name, :module]
end
