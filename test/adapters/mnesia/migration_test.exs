defmodule ActiveMemory.Adapters.Mnesia.MigrationTest do
  use ExUnit.Case, async: false

  # By default these tests are skipped becasue they cause errors. To run
  # mix test test/adapters/mnesia/migration_test.exs --include migration

  alias Test.Support.People.{Person, Store}

  describe "migrate_table_options/1" do
    @tag :migration
    test "updates the access_mode on startup" do
      assert :mnesia.create_table(Person,
               access_mode: :read_only,
               attributes: [:uuid, :email, :first, :last, :hair_color, :age, :cylon?],
               index: [:last, :cylon?],
               ram_copies: [node()],
               type: :set
             ) == {:atomic, :ok}

      assert :mnesia.table_info(Person, :access_mode) == :read_only

      {:ok, pid} = Store.start_link()

      assert :mnesia.table_info(Person, :access_mode) == :read_write

      Process.exit(pid, :kill)
    end

    @tag :migration
    test "updates the disc copies on startup" do
      File.cwd!() |> Path.join("Mnesia.nonode@nohost") |> File.rm_rf()
      :stopped = :mnesia.stop()
      :ok = :mnesia.create_schema([node()])
      :ok = :mnesia.start()

      assert :mnesia.create_table(Person,
               attributes: [:uuid, :email, :first, :last, :hair_color, :age, :cylon?],
               index: [:last, :cylon?],
               disc_copies: [node()],
               type: :set
             ) == {:atomic, :ok}

      assert :mnesia.table_info(Person, :disc_copies) == [:nonode@nohost]

      {:ok, pid} = Store.start_link()

      assert :mnesia.table_info(Person, :disc_copies) == []
      assert :mnesia.table_info(Person, :ram_copies) == [:nonode@nohost]

      {:ok, _} = File.cwd!() |> Path.join("Mnesia.nonode@nohost") |> File.rm_rf()

      Process.exit(pid, :kill)
    end

    @tag :migration
    test "updates the disc_only_copies on startup" do
      File.cwd!() |> Path.join("Mnesia.nonode@nohost") |> File.rm_rf()
      :stopped = :mnesia.stop()
      :ok = :mnesia.create_schema([node()])
      :ok = :mnesia.start()

      assert :mnesia.create_table(Person,
               attributes: [:uuid, :email, :first, :last, :hair_color, :age, :cylon?],
               index: [:last, :cylon?],
               disc_only_copies: [node()],
               type: :set
             ) == {:atomic, :ok}

      assert :mnesia.table_info(Person, :disc_only_copies) == [:nonode@nohost]

      {:ok, pid} = Store.start_link()

      assert :mnesia.table_info(Person, :disc_only_copies) == []
      assert :mnesia.table_info(Person, :ram_copies) == [:nonode@nohost]

      {:ok, _} = File.cwd!() |> Path.join("Mnesia.nonode@nohost") |> File.rm_rf()

      Process.exit(pid, :kill)
    end

    @tag :migration
    test "replaces the indexes on startup" do
      :stopped = :mnesia.stop()
      :ok = :mnesia.delete_schema([node()])
      :ok = :mnesia.start()

      assert :mnesia.create_table(Person,
               attributes: [:uuid, :email, :first, :last, :hair_color, :age, :cylon?],
               index: [:email, :first],
               type: :set
             ) == {:atomic, :ok}

      assert :mnesia.table_info(Person, :index) == [4, 3]

      {:ok, pid} = Store.start_link()

      assert :mnesia.table_info(Person, :index) == [8, 5]

      Process.exit(pid, :kill)
    end

    @tag :migration
    test "adds new indexes on startup if none exist" do
      :stopped = :mnesia.stop()
      :ok = :mnesia.delete_schema([node()])
      :ok = :mnesia.start()

      assert :mnesia.create_table(Person,
               attributes: [:uuid, :email, :first, :last, :hair_color, :age, :cylon?],
               type: :set
             ) == {:atomic, :ok}

      assert :mnesia.table_info(Person, :index) == []

      {:ok, pid} = Store.start_link()

      assert :mnesia.table_info(Person, :index) == [8, 5]

      Process.exit(pid, :kill)
    end

    @tag :migration
    test "removes old indexes on startup" do
      :stopped = :mnesia.stop()
      :ok = :mnesia.delete_schema([node()])
      :ok = :mnesia.start()

      assert :mnesia.create_table(Person,
               index: [:last, :first, :cylon?],
               attributes: [:uuid, :email, :first, :last, :hair_color, :age, :cylon?],
               type: :set
             ) == {:atomic, :ok}

      assert :mnesia.table_info(Person, :index) == [8, 4, 5]

      {:ok, pid} = Store.start_link()

      assert :mnesia.table_info(Person, :index) == [5, 8]

      Process.exit(pid, :kill)
    end

    @tag :migration
    test "updates the migrate load order on startup" do
      File.cwd!() |> Path.join("Mnesia.nonode@nohost") |> File.rm_rf()
      :stopped = :mnesia.stop()
      :ok = :mnesia.create_schema([node()])
      :ok = :mnesia.start()

      assert :mnesia.create_table(Person,
               attributes: [:uuid, :email, :first, :last, :hair_color, :age, :cylon?],
               index: [:last, :cylon?],
               load_order: 5,
               type: :set
             ) == {:atomic, :ok}

      assert :mnesia.table_info(Person, :load_order) == 5

      {:ok, pid} = Store.start_link()

      assert :mnesia.table_info(Person, :load_order) == 0

      {:ok, _} = File.cwd!() |> Path.join("Mnesia.nonode@nohost") |> File.rm_rf()

      Process.exit(pid, :kill)
    end

    @tag :migration
    test "updates the majority on startup" do
      File.cwd!() |> Path.join("Mnesia.nonode@nohost") |> File.rm_rf()
      :stopped = :mnesia.stop()
      :ok = :mnesia.create_schema([node()])
      :ok = :mnesia.start()

      assert :mnesia.create_table(Person,
               attributes: [:uuid, :email, :first, :last, :hair_color, :age, :cylon?],
               index: [:last, :cylon?],
               majority: true,
               type: :set
             ) == {:atomic, :ok}

      info = :mnesia.table_info(Person, :all)

      assert Keyword.get(info, :majority)

      {:ok, pid} = Store.start_link()

      updated = :mnesia.table_info(Person, :all)

      refute Keyword.get(updated, :majority)

      {:ok, _} = File.cwd!() |> Path.join("Mnesia.nonode@nohost") |> File.rm_rf()

      Process.exit(pid, :kill)
    end
  end
end
