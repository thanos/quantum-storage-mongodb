defmodule QuantumStorageMongodb do
  @moduledoc """
  `MongoDB` based implementation of a `Quantum.Storage`.

  To use this  `Quantum.Storage` add it to
  """

  use GenServer

  require Logger

  @behaviour Quantum.Storage

  @supported_mongo_options [
    :url,
    :host,
    :port,
    :database,
    :username,
    :password,
    :auth_source,
    :ssl,
    :pool_size,
    :seeds
  ]

  #
  #
  # API
  #
  #

  @doc false
  def start_link(opts) do
    Logger.info("opts: #{inspect(opts)}")
    GenServer.start_link(__MODULE__, opts, opts)
  end

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
    Logger.info("opts: #{inspect(opts)}")
    collection = opts |> Keyword.fetch!(:collection)

    opts =
      opts
      |> Keyword.take(@supported_mongo_options)

    db =
      case opts |> Keyword.get(:repo) do
        nil ->
          {:ok, db} = Mongo.start_link(opts)
          db

        repo ->
          Keyword.get(repo.config(), :name)
      end

    {:ok,
     %{
       db: db,
       collection: collection
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
      "readable" => readable(job),
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

    updated_job =
      job
      |> decode_job!()
      |> Quantum.Job.set_state(job_state)

    Mongo.update_one(db, collection, %{"_id" => id}, %{
      "$set" => %{
        "job" => encode_job(updated_job),
        "readable" => readable(job)
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
       %{"date" => date} -> date |> decode_date!
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
         |> Enum.map(fn %{"job" => job} -> job |> decode_job! end)
     end, state}
  end

  def marked_used(db, collection) do
    Mongo.insert_one(db, collection, %{
      "_id" => "used",
      "state" => true,
      "type" => "bookkeeping"
    })
  end

  @doc false
  def encode_job(job), do: job |> :erlang.term_to_binary() |> Base.encode16()

  @doc false
  def decode_job!(job), do: job |> Base.decode16!() |> :erlang.binary_to_term()

  @doc false
  def encode_name(nil), do: nil
  def encode_name(name) when is_atom(name), do: name |> Atom.to_string()
  def encode_name(name) when is_reference(name), do: name |> inspect(limit: :infininty)

  def decode_name!(nil), do: nil

  def decode_name!("#Reference<" <> ref_part) do
    length = String.length(ref_part)
    ref_part |> String.slice(0, length - 1)
    IEx.Helpers.ref(ref_part)
  end

  def decode_name!(name_str), do: name_str |> String.to_atom()

  @doc false
  def encode_date(date), do: date |> NaiveDateTime.to_iso8601()

  @doc false
  def decode_date!(date_str), do: date_str |> NaiveDateTime.from_iso8601!()

  def readable(job), do: job |> inspect()
end
