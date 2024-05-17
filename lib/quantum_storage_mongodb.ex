defmodule QuantumStorageMongodb do
  @moduledoc """
  `MongoDB` based implementation of a `Quantum.Storage`.
  """

  use GenServer

  require Logger

  @behaviour Quantum.Storage

  #
  #
  # API
  #
  #

  @doc false
  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, opts)

  @doc false
  @impl Quantum.Storage
  def jobs(storage_pid), do: GenServer.call(storage_pid, :jobs)

  @doc false
  @impl Quantum.Storage
  def add_job(storage_pid, job) do
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

  #
  #
  # SERVER
  #
  #

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
  @impl GenServer
  def handle_cast({:add_job, job}, %{db: db, collection: collection} = state) do
    Logger.debug("handle_cast #{inspect({:add_job, job})}")
    marked_used(db, collection)

    Mongo.insert_one(db, collection, %{
      "_id" => encode_name(job.name),
      "job" => encode_job(job),
      "type" => "data"
    })

    {:noreply, state}
  end

  @doc false
  @impl GenServer
  def handle_cast({:delete_job, job_name}, %{db: db, collection: collection} = state) do
    Mongo.delete_one(db, collection, %{"_id" => encode_name(job_name)})
    {:noreply, state}
  end

  @doc false
  @impl GenServer
  def handle_cast(
        {:update_job_state, job_name, job_state},
        %{db: db, collection: collection} = state
      ) do
    %{"_id" => id, "job" => job} =
      Mongo.find_one(db, collection, %{"_id" => encode_name(job_name)})

    Mongo.update_one(db, collection, %{"_id" => id}, %{
      "$set" => %{
        "job" =>
          job
          |> decode_job()
          |> Quantum.Job.set_state(job_state)
          |> encode_job()
      }
    })

    {:noreply, state}
  end

  @doc false
  @impl GenServer
  def handle_cast(:purge, %{db: db, collection: collection} = state) do
    Mongo.delete_many(db, collection, %{})
    {:noreply, state}
  end

  @doc false
  @impl GenServer
  def handle_cast(
        {:update_last_execution_date, last_execution_date},
        %{db: db, collection: collection} = state
      ) do
    update = %{
      "date" => last_execution_date |> encode_date,
      "type" => "bookkeeping"
    }

    Mongo.replace_one(db, collection, %{"_id" => "last_execution_date"}, update, upsert: true)
    {:noreply, state}
  end

  @doc false
  @impl GenServer
  def handle_call(:last_execution_date, _from, %{db: db, collection: collection} = state) do
    # Mongo.find(db, collection, %{})
    # |> IO.inspect(label: "before")
    {:reply,
     Mongo.find_one(db, collection, %{"_id" => "last_execution_date"})
     |> case do
       nil -> :unknown
       %{"date" => date} -> date |> decode_date
     end, state}
  end

  @doc false
  @impl GenServer
  def handle_call(:jobs, _from, %{db: db, collection: collection} = state) do
    {:reply,
     Mongo.find(db, collection, %{})
     |> Enum.to_list()
     |> case do
       [
         %{
           "_id" => "used",
           "state" => true
         }
       ] ->
         []

       [] ->
         :not_applicable

       jobs ->
         jobs
         |> Enum.reject(fn %{"type" => type} -> type == "bookkeeping" end)
         |> Enum.map(fn %{"job" => job} -> job |> decode_job end)
     end, state}
  end

  def marked_used(db, collection) do
    Mongo.insert_one(db, collection, %{
      "_id" => "used",
      "state" => true,
      "type" => "bookkeeping"
    })
  end

  def encode_job(job), do: :erlang.term_to_binary(job)
  def decode_job(job), do: :erlang.binary_to_term(job)
  def encode_name(name), do: :erlang.term_to_binary(name)
  def encode_date(date), do: :erlang.term_to_binary(date)
  def decode_date(date), do: :erlang.binary_to_term(date)
end
