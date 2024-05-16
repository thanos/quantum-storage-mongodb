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
      start_supervised!(
        {QuantumStorageMongodb,
         collection: Module.concat(__MODULE__, test), url: "mongodb://localhost:27017/my-database"}
      )

    assert :ok = QuantumStorageMongodb.purge(storage)

    {:ok, storage: storage}
  end

  describe "add_job/2" do
    test "adds job", %{storage: storage} do
      Mongo
      |> stub(:insert_one, fn _db, _col, _obj -> :stub end)
      |> expect(:insert_one, fn db, col, obj ->
        IO.inspect({db, col, obj})
        :ok
      end)

      job = Scheduler.new_job()
      assert :ok = QuantumStorageMongodb.add_job(storage, job)
      # assert [^job] = QuantumStorageMongodb.jobs(storage)
    end
  end
end
