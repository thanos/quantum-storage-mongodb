defmodule QuantumStorageMongodbTest do
  @moduledoc false
  use ExUnit.Case
  use Mimic
  doctest QuantumStorageMongodb

  defmodule Scheduler do
    @moduledoc false

    use Quantum, otp_app: :quantum_storage_mongodb
  end

  setup %{test: test} do
    storage =
      start_supervised!({
        QuantumStorageMongodb,
        collection: "QuantumStorageMongodb.test", url: "mongodb://localhost:27017/my-database"
      })

    assert :ok = QuantumStorageMongodb.purge(storage)

    {:ok, storage: storage}
  end

  describe "purge/1" do
    test "purges correct module", %{storage: storage} do
      assert :ok = QuantumStorageMongodb.add_job(storage, Scheduler.new_job())
      assert :ok = QuantumStorageMongodb.purge(storage)
      assert :not_applicable = QuantumStorageMongodb.jobs(storage)
    end
  end

  describe "add_job/2" do
    test "adds job", %{storage: storage} do
      # Mongo
      # |> stub(:insert_one, fn _db, _col, _obj -> :stub end)
      # |> expect(:insert_one, fn db, col, obj ->
      #   IO.inspect({db, col, obj})
      #   :ok
      # end)

      job = Scheduler.new_job()
      assert :ok = QuantumStorageMongodb.add_job(storage, job)
      assert [^job] = QuantumStorageMongodb.jobs(storage)
    end
  end

  describe "delete_job/2" do
    test "deletes job", %{storage: storage} do
      job = Scheduler.new_job()
      assert :ok = QuantumStorageMongodb.add_job(storage, job)
      assert :ok = QuantumStorageMongodb.delete_job(storage, job.name)
      assert [] = QuantumStorageMongodb.jobs(storage)
    end

    test "does not fail when deleting unknown job", %{storage: storage} do
      job = Scheduler.new_job()
      assert :ok = QuantumStorageMongodb.add_job(storage, job)
      assert :ok = QuantumStorageMongodb.delete_job(storage, make_ref())
    end
  end

  describe "update_job_state/2" do
    test "updates job", %{storage: storage} do
      job = Scheduler.new_job()
      assert :ok = QuantumStorageMongodb.add_job(storage, job)
      assert :ok = QuantumStorageMongodb.update_job_state(storage, job.name, :inactive)
      assert [%{state: :inactive}] = QuantumStorageMongodb.jobs(storage)
    end

    test "does not fail when updating unknown job", %{storage: storage} do
      job = Scheduler.new_job()
      assert :ok = QuantumStorageMongodb.add_job(storage, job)

      assert :ok = QuantumStorageMongodb.update_job_state(storage, make_ref(), :inactive)
    end
  end

  describe "update_last_execution_date/2" do
    test "sets time on scheduler", %{storage: storage} do
      date = NaiveDateTime.utc_now()
      assert :ok = QuantumStorageMongodb.update_last_execution_date(storage, date)
      assert ^date = QuantumStorageMongodb.last_execution_date(storage)
    end
  end

  describe "last_execution_date/1" do
    test "gets time", %{storage: storage} do
      date = NaiveDateTime.utc_now()
      assert :ok = QuantumStorageMongodb.update_last_execution_date(storage, date)
      assert ^date = QuantumStorageMongodb.last_execution_date(storage)
    end

    test "get unknown otherwise", %{storage: storage} do
      assert :unknown = QuantumStorageMongodb.last_execution_date(storage)
    end
  end
end
