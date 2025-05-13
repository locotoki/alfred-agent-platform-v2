FROM pgvector/pgvector:pg14

# Install required dependencies
RUN apt-get update && apt-get install -y \
    git \
    make \
    postgresql-server-dev-14 \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Build and install pgjwt
RUN cd /tmp \
    && git clone https://github.com/michelp/pgjwt.git \
    && cd pgjwt \
    && make \
    && make install

# Install pg_cron extension
RUN apt-get update && apt-get install -y postgresql-14-cron && \
    rm -rf /var/lib/apt/lists/*