defmodule Test.Support.Dogs.Dog do
  use ActiveMemory.Table,
    attributes: [:name, :breed, :weight, fixed?: true, nested: %{one: nil, default: true}]
end
