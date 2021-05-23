# Commanded Generator

Mix task to create a new Commanded project.

The task will create a new Elixir application configured to use Commanded,
EventStore, Commanded Ecto projections, and Ecto.

You will need to clone this repository to use the `commanded.new` Mix task.

```shell
git clone git@github.com:commanded/generator.git commanded_generator
cd commanded_generator
mix do deps.get, compile
```

## Usage

```shell
mix commanded.new PATH [--module MODULE] [--app APP]
```

It expects the path of the project as an argument.

### Scaffold a project from a Miro board

```shell
mix commanded.new PATH --miro BOARD_ID
```
