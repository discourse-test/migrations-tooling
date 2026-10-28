# Migrations Tooling

A Discourse plugin with the v2 migration tools. It also works on its own, without a Discourse install.

The code is split into four path gems in `gems/`:

- `core/` — `Migrations::*`: SQLite schemas, DB infrastructure, IntermediateDB models, and the
  conversion framework (`Migrations::Conversion::*`).
- `tooling/` — `Migrations::Tooling::*`: the schema DSL, `disco schema` commands, benchmarks.
- `converters/` — `Migrations::Converters::*`: public converter implementations + source adapters.
- `importer/` — `Migrations::Importer::*`: the row importer and the uploads importer.

The command framework comes from the `discourse-disco-cli` gem and the progress output from
`mini_progress`. Both are on GitHub Packages, see [Installing gems](#installing-gems).

## Command line interface

`bin/disco` is the only launcher. Run it without arguments, or with `--help`, for the list of
commands:

```bash
bin/disco --help
```

It runs in one of two modes, depending on where the plugin is:

- **Inside Discourse** (`<discourse>/plugins/migrations-tooling`): it boots Rails with core's
  Gemfile first, which also loads the plugin's gems. All commands work.
- **Standalone** (anywhere else, or with `DISCO_STANDALONE=1`): it uses the plugin's Gemfile and
  doesn't boot Rails. Commands that need Rails (`import`, `upload`, `schema`, `check`) and
  converters that need Discourse's files (`convert discourse`) refuse to run.

The commands are registered in `disco/register.rb`.

## Converters

Public converters live in `gems/converters/lib/migrations/converters/`. To run a private
(closed-source) converter, put its code in a subdirectory of `private/converters/` in the plugin
(or point `MIGRATIONS_PRIVATE_CONVERTERS_PATH` at it).

A converter that reads files from a Discourse install declares `requires_discourse!`. The
Discourse converter does, because its markdown engine builds its parser bundle from core's sources
(it caches the bundle under `<discourse>/tmp/migrations/`).

### Source DB adapters and fork safety

Worker processes inherit the source DB connection's socket from the main process. Whether
that's dangerous depends on the client library: a destructor that only closes the file
descriptor is harmless (the parent still holds it, so the kernel sends nothing over the
wire), but a destructor that writes a protocol goodbye kills the parent's session as soon
as a worker exits — libpq sends a Terminate message, MySQL clients send `COM_QUIT`.

`Adapter::Postgres` handles this by registering a `ForkManager.after_fork_child` hook that
calls `discard!` in each worker: the inherited socket is redirected to `/dev/null`, and any
later use of the adapter in the worker raises `DiscardedError`. New adapters should follow
the same pattern. The discard mechanism itself is library-specific — mysql2 has
`automatic_close = false`, trilogy has a native `discard!`. To check whether a library
needs one at all: connect, fork an empty child that exits normally, wait for it, and query
again from the parent (see the fork-safety specs in `postgres_spec.rb`).

### Partitioning large steps

Most steps run in a single worker. A handful are large enough that it's worth
splitting them across CPU cores, so the framework can run one worker per chunk of
the source. A step opts in from its `source` block:

```ruby
source do
  reads_table "topic_users", where: "user_id > 0"
  partition_by :topic_id
end
```

`reads_table` is the part that reads a whole table: it defines `items`
(`SELECT * FROM topic_users WHERE …`) and `max_progress` (the row count), filtered
by `where`. It works on its own, without partitioning — a plain table-copy step
declares just `reads_table` and writes neither method. `partition_by` adds the
split: it takes the key (normally a single indexed column, so each chunk is an
index range scan; pass an array for a composite key) and reuses the table and
filter from `reads_table`, so it only needs the column. When both are present the
generated queries add the chunk to their `WHERE` automatically.

Override `items` when you need specific columns, a join, or a particular order —
and then add `partition_slice` to its `WHERE` yourself:

```ruby
def items
  @source_db.query("SELECT id, name FROM topic_users WHERE #{partition_slice} AND name IS NOT NULL")
end
```

The framework does the rest. Before forking, it asks the adapter for the chunk
boundaries — evenly sized chunks over a numeric key, or a sorted-key scan for a
text/UUID/composite key. It then forks one worker per chunk; each worker reads
its `[lower, upper)` slice (that's what `partition_slice` expands to), writes its
own SQLite shard, and the shards are merged back into the run database.

Two things to get right:

- **In a custom query, add `partition_slice` to the `WHERE`.** Miss it and each
  worker reads the whole source instead of its slice — duplicated work and wrong
  counts.
- **Only partition order-independent steps.** Workers run concurrently and their
  output is merged, so there is no global order across the step. A running total
  or a sequence number across all rows can't be partitioned. Deduplication can,
  but do it in the source query (`DISTINCT ON`, a window function, a view) and
  partition on the dedup key, rather than keeping state in `process`.

## Schema DSL

The schema DSL lives in `gems/tooling/lib/migrations/tooling/schema/dsl/`. Config sources
are in `gems/tooling/config/schema/`. Generated artifacts (SQL, models, enums) are written
into `gems/core/`. See [docs/schema-configuration.md](docs/schema-configuration.md).

Key files:
- `table_builder.rb` - DSL for defining table configs
- `schema_resolver.rb` - Resolves DSL config + DB introspection into final schema
- `conventions_builder.rb` - Global column conventions (renames, type overrides)
- `generator.rb` - Generates SQL, models, and enums from resolved schema
- `validator.rb` - Validates DSL config
- `resolved_schema_validator.rb` - Validates resolved schema before generation

## Development

### Installing gems

`mini_progress` and `discourse-disco-cli` come from GitHub Packages, which needs a token with
`read:packages` even for public packages:

```bash
export BUNDLE_RUBYGEMS__PKG__GITHUB__COM="<github user>:<token>"
bundle install
```

Inside Discourse, the plugin's `Gemfile` and `Gemfile.lock` are installed when Discourse boots
(`# gemfile: true` in `plugin.rb`). After changing the Gemfile, run `bundle lock --add-checksums`
and commit the lock.

### Running tests

`bin/rspec` runs a gem's specs with the plugin's Gemfile. Run it from the gem directory:

```bash
cd gems/core       && ../../bin/rspec
cd gems/tooling    && ../../bin/rspec
cd gems/converters && ../../bin/rspec
cd gems/importer   && ../../bin/rspec
```

Specs tagged `:discourse` read files from a Discourse install and run only when the plugin is
inside one. Specs tagged `:rails` also need a booted Rails environment; they run inside Discourse
with `MIGRATIONS_RAILS=1`:

```bash
cd gems/<gem> && MIGRATIONS_RAILS=1 ../../bin/rspec --tag rails
```

### Linting

```bash
bin/lint
```

Runs RuboCop with autocorrect and formats with Syntax Tree. `bundle exec rubocop` and
`bundle exec stree check Gemfile '**/*.rb' '**/*.rake'` check without changing files.
