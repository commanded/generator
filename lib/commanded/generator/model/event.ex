defmodule Commanded.Generator.Model.Event do
  alias __MODULE__

  @type t :: %Event{
          name: String.t(),
          module: atom()
        }

  defstruct [:name, :module]
end
