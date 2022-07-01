defmodule Test.Support.Dogs.Store do
  use ActiveMemory.Store,
    table: Test.Support.Dogs.Dog,
    type: :ets,
    before_init: [{:run_me, ["Blue"]}],
    initial_state: {:initial_state, ["value", "next_value"]}

  def run_me(name) do
    %Test.Support.Dogs.Dog{
      name: name,
      breed: "English PitBull",
      weight: 40,
      fixed?: false
    }
    |> write()

    :ok
  end

  def initial_state(arg, arg2) do
    {:ok,
     %{
       key: arg,
       next: arg2,
       now: DateTime.utc_now()
     }}
  end
end
