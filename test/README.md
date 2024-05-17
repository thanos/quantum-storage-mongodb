# QuantumStoragePersistentMongodb

[![Hex.pm Version](http://img.shields.io/hexpm/v/quantum_storage_mongodb.svg)](https://hex.pm/packages/quantum_storage_mongodb)

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `quantum_storage_persistent_mongodb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:quantum_storage_persistent_mongodb, "~> 0.1.0"}
  ]
end
```

To enable the storage adpater, add this to your config.exs:

```elixir
use Mix.Config

config :quantum_test, QuantumTest.Scheduler,
  storage: QuantumStorageMongodb

```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/quantum_storage_persistent_mongodb>.
