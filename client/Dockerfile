FROM oven/bun:1.2-slim

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at build time (shallow clone for speed)
RUN git clone --depth 1 https://github.com/Ignies/OpenMu-Client-Babylon.git .

# Install dependencies
RUN bun install

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 4173 3000

ENTRYPOINT ["/entrypoint.sh"]
