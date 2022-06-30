defmodule ActiveMemory.Store do
  alias ActiveMemory.Definition

  defmacro __using__(opts) do
    opts = Macro.expand(opts, __CALLER__)

    quote do
      import unquote(__MODULE__)

      opts = unquote(opts)

      @table_name Keyword.get(opts, :table)
      @table_type Keyword.get(opts, :type, :mnesia)
      @adapter Definition.set_adapter(@table_type)
      @seed_file Keyword.get(opts, :seed_file, nil)

      def start_link(_opts \\ []) do
        GenServer.start_link(__MODULE__, [], name: __MODULE__)
      end

      def init(_) do
        create_table()
        run_seeds(@seed_file)

        {:ok, %{table_name: @table_name}}
      end

      def all, do: :erlang.apply(@adapter, :all, [@table_name])

      def create_table do
        :erlang.apply(@adapter, :create_table, [@table_name, []])
      end

      def delete(%{__struct__: @table_name} = struct) do
        :erlang.apply(@adapter, :delete, [struct, @table_name])
      end

      def delete(nil), do: :ok

      def delete(_), do: {:error, :bad_schema}

      def delete_all do
        :erlang.apply(@adapter, :delete_all, [@table_name])
      end

      def one(query) do
        :erlang.apply(@adapter, :one, [query, @table_name])
      end

      def reload_seeds do
        GenServer.call(__MODULE__, :reload_seeds)
      end

      def select(query) when is_map(query) do
        :erlang.apply(@adapter, :select, [query, @table_name])
      end

      def select({_operand, _lhs, _rhs} = query) do
        :erlang.apply(@adapter, :select, [query, @table_name])
      end

      def select(_), do: {:error, :bad_select_query}

      def state do
        GenServer.call(__MODULE__, :state)
      end

      def withdraw(query) do
        with {:ok, %{} = record} <- one(query),
             :ok <- delete(record) do
          {:ok, record}
        else
          {:ok, nil} -> {:ok, nil}
          {:error, message} -> {:error, message}
        end
      end

      def write(%@table_name{} = struct) do
        :erlang.apply(@adapter, :write, [struct, @table_name])
      end

      def write(_), do: {:error, :bad_schema}

      def handle_call(:reload_seeds, _from, state) do
        {:reply, run_seeds(@seed_file), state}
      end

      def handle_call(:state, _from, state), do: {:reply, state, state}

      defp run_seeds(nil), do: :ok

      defp run_seeds(file) when is_binary(file) do
        with {seeds, _} when is_list(seeds) <- Code.eval_file(@seed_file),
             true <- write_seeds(seeds) do
          {:ok, :seed_success}
        else
          {:error, message} -> {:error, message}
          _ -> {:error, :seed_failure}
        end
      end

      defp write_seeds(seeds) do
        seeds
        |> Task.async_stream(&write(&1))
        |> Enum.all?(fn {:ok, {result, _seed}} -> result == :ok end)
      end
    end
  end
end
