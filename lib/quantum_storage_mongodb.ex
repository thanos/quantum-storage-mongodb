defmodule QuantumStorageMongodb do
  @moduledoc """
  `MongoDB` based implementation of a `Quantum.Storage`.
  """

  use GenServer

  require Logger

  @behaviour Quantum.Storage

  @doc false
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, opts)

  @doc false
  @impl GenServer
  def init(opts) do
    {:ok, conn} =
      Mongo.start_link(
        url: opts |> Keyword.fetch!(:url)
        # username: opts |> Keyword.fetch!(:username),
        # password: opts |> Keyword.fetch!(:password),
        # auth_source: opts |> Keyword.fetch!(:auth_source)
      )

    {:ok,
     %{
       db: conn,
       collection: opts |> Keyword.fetch!(:collection)
     }}
  end

  @doc false
  @impl Quantum.Storage
  def jobs(storage_pid), do: GenServer.call(storage_pid, :jobs)

  @doc false
  @impl Quantum.Storage
  def add_job(storage_pid, job) do
    Logger.debug("#{inspect({storage_pid, {:add_job, job}})}")
    IO.inspect({storage_pid, {:add_job, job}})
    GenServer.cast(storage_pid, {:add_job, job})
  end

  @doc false
  @impl Quantum.Storage
  def delete_job(storage_pid, job_name), do: GenServer.cast(storage_pid, {:delete_job, job_name})

  @doc false
  @impl Quantum.Storage
  def update_job_state(storage_pid, job_name, state),
    do: GenServer.cast(storage_pid, {:update_job_state, job_name, state})

  @doc false
  @impl Quantum.Storage
  def last_execution_date(storage_pid), do: GenServer.call(storage_pid, :last_execution_date)

  @doc false
  @impl Quantum.Storage
  def update_last_execution_date(storage_pid, last_execution_date),
    do: GenServer.cast(storage_pid, {:update_last_execution_date, last_execution_date})

  @doc false
  @impl Quantum.Storage
  def purge(storage_pid), do: GenServer.cast(storage_pid, :purge)

  @doc false
  @impl GenServer
  def handle_cast({:add_job, job}, %{db: db, collection: collection} = state) do
    Logger.debug("#{inspect({:add_job, job})}")
    IO.inspect({:add_job, job})
    Mongo.insert_one(db, collection, %{"_id" => job.name, "job" => job})
    {:noreply, state}
  end

  def handle_cast({:delete_job, job_name}, %{db: db, collection: collection} = state) do
    Mongo.delete_one(db, collection, %{"_id" => job_name})
    {:noreply, state}
  end

  def handle_cast(
        {:update_job_state, job_name, job_state},
        %{db: db, collection: collection} = state
      ) do
    Mongo.update_one(db, collection, %{"_id" => job_name}, %{"job" => job_state})
    {:noreply, state}
  end

  def handle_cast(
        {:update_last_execution_date, last_execution_date},
        %{db: db, collection: collection} = state
      ) do
    Mongo.update_one(db, collection, %{"_id" => "last_execution_date"}, %{
      "date" => last_execution_date
    })

    {:noreply, state}
  end

  def handle_cast(:purge, %{db: db, collection: collection} = state) do
    Mongo.delete_many(db, collection, %{})
    {:noreply, state}
  end

  @doc false
  @impl GenServer
  def handle_call(:jobs, _from, %{db: db, collection: collection} = state) do
    {:reply,
     Mongo.find(db, collection, %{})
     |> Enum.to_list()
     |> case do
       [] ->
         :not_applicable

       jobs ->
         jobs
     end, state}
  end

  def handle_call(:last_execution_date, _from, %{db: db, collection: collection} = state) do
    {:reply,
     Mongo.find_one(db, collection, %{"id" => "last_execution_date"})
     |> case do
       nil -> :unknown
       %{"date" => date} -> date
     end, state}
  end
end
