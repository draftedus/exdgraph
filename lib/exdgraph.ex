defmodule ExDgraph do
  @moduledoc """
  A gRPC based Dgraph client in Elixir.
  """

  use Supervisor

  @pool_name :ex_dgraph_pool
  @timeout 15_000

  alias ExDgraph.Api.{Dgraph, Request, Response, Mutation, Operation}
  alias ExDgraph.Utils

  @type conn :: DBConnection.conn()
  # @type transaction :: DBConnection.t()

  @doc """
  Start the connection process and connect to Dgraph

  ## Options:
    - `:hostname` - Server hostname (default: DGRAPH_HOST env variable, then localhost);
    - `:port` - Server port (default: DGRAPH_PORT env variable, then 9080);
    - `:username` - Username;
    - `:password` - User password;
    - `:pool_size` - maximum pool size;
    - `:max_overflow` - maximum number of workers created if pool is empty
    - `:timeout` - Connect timeout in milliseconds (default: `#{@timeout}`)
       Poolboy will block the current process and wait for an available worker,
       failing after a timeout, when the pool is full;

  ## Example of valid configurations (i.e. defined in config/dev.exs) and usage:

      config :ex_dgraph, ExDgraph,
        hostname: 'localhost',
        port: 9080,
        pool_size: 5,
        max_overflow: 1

  Sample code:

      opts = Application.get_env(:ex_dgraph, ExDgraph)
      {:ok, pid} = ExDgraph.start_link(opts)

      TODO: Query example
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def init(opts) do
    cnf = Utils.default_config(opts)

    children = [
      {ExDgraph.ConfigAgent, cnf},
      DBConnection.child_spec(ExDgraph.Protocol, pool_config(cnf))
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Returns a pool name which can be used to acquire a connection.
  """
  def conn, do: pool_name()

  @doc """
  returns an environment specific ExDgraph configuration.
  """
  def config, do: ConfigAgent.get_config()

  @doc false
  def config(key), do: Keyword.get(config(), key)

  @doc false
  def config(key, default) do
    Keyword.get(config(), key, default)
  rescue
    _ -> default
  end

  @doc false
  def pool_name, do: @pool_name

  ## Helpers
  ######################

  defp pool_config(cnf) do
    [
      name: {:local, pool_name()},
      pool: Keyword.get(cnf, :pool),
      pool_size: Keyword.get(cnf, :pool_size),
      pool_overflow: Keyword.get(cnf, :max_overflow)
    ]
  end
end
