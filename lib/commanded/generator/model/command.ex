defmodule Commanded.Generator.Model.Command do
  alias Commanded.Generator.Model.Field
  alias __MODULE__

  @type t :: %Command{
          name: String.t(),
          module: atom(),
          fields: list(Field.t())
        }

  defstruct [:name, :module, fields: []]

  def new(namespace, name, fields \\ []) do
    module = Module.concat([namespace, String.replace(name, " ", "")])

    %Command{name: name, module: module, fields: fields}
  end
end
