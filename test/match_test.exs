defmodule ActiveMemory.MatchTest do
  use ExUnit.Case

  alias ActiveMemory.Match

  defmodule Tester do
    use Memento.Table, attributes: [:email, :first, :last, :hair_color, :shoe_size]
  end

  defmodule Tester.Store do
    use ActiveMemory.Store, table: Tester
  end

  setup_all do
    {:ok, pid} = Tester.Store.start_link()
    {:ok, %{pid: pid}}
  end

  describe "build_match_query/2" do
    test "returns the query strings in the correct positions" do
      query_map = %{last: "boeger", shoe_size: "13"}

      assert {:ok, {:_, :_, "boeger", :_, "13"}} == Match.build(Tester, query_map)
    end

    test "returns error for keys that do not match" do
      query_map = %{ears: "two", nose: "kinda big"}

      assert {:error, :query_schema_mismatch} == Match.build(Tester, query_map)
    end
  end
end
