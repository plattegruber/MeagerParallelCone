# Use the latest Elixir image
FROM elixir:1.16.3

# Install hex package manager and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create app directory
WORKDIR /app

# Install Alpine dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Copy over project files
COPY . .

# Install dependencies
RUN mix deps.get
RUN mix deps.compile

# Compile assets
RUN mix assets.deploy

# Compile app
RUN mix compile

# Set environment variables
ENV MIX_ENV=prod

# Run migrations and start app
CMD ["mix", "phx.server"]