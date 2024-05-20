# Quantum Storage Persistent Mongodb

[![Hex.pm Version](http://img.shields.io/hexpm/v/quantum_storage_mongodb.svg)](https://hex.pm/packages/quantum_storage_mongodb)

[![Coverage Status](https://coveralls.io/repos/github/thanos/quantum-storage-mongodb/badge.svg?branch=main)](https://coveralls.io/github/thanos/quantum-storage-mongodb?branch=main)

## What

Quantum storage adapter for mongodb. This is a copy of persistent ets implementation

## Why

There quite a few big fat ords where the only approved object/doc storage is MongoDB. The same institutions often only offer ephemeral block storage for the VMs. Hence I kindo of need to build this lib.

## Who

Some big company is using it in prod. Please let me know (in a ticket) if you do too.

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

````elixir
use Mix.Config

config :quantum_test, QuantumTest.Scheduler,
  storage: QuantumStorageMongodb
   storage_opts: [ url: "mongodb://localhost:27017/my-database", collection: "quantum"]

   Supports the following Mongo options:
    ```elixir
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
````

see https://hexdocs.pm/mongodb_driver/readme.html#usage

```

```
