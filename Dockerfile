FROM lukemathwalker/cargo-chef:latest-rust-1 AS chef

WORKDIR /app

# stage 1, prepare the recipe for build caching
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# stage 2, copy over source code and build
FROM chef AS rust_builder
COPY --from=planner /app/recipe.json recipe.json

# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json

# Build application
COPY . .
RUN cargo build --release

# Final stage
FROM debian:bullseye-slim
WORKDIR /app
COPY --from=rust_builder /app/target/release/reth-indexer ./indexer

# No need to create directory or declare VOLUME since we're using an existing one
ENTRYPOINT ["/app/indexer"]
