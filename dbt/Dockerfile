# dbt local image for Apple Silicon (arm64) and amd64
FROM python:3.11-slim

# System deps for psycopg2 & builds
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev git && rm -rf /var/lib/apt/lists/*

# Install dbt for Postgres (pin the version you want)
RUN pip install --no-cache-dir "dbt-postgres==1.8.1"

WORKDIR /usr/app
CMD ["bash"]
