defmodule QuantumStoragePersistentMongodbTest do
  use ExUnit.Case
  doctest QuantumStoragePersistentMongodb

  test "greets the world" do
    assert QuantumStoragePersistentMongodb.hello() == :world
  end
end
