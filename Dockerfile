FROM rust:1.85-bookworm AS builder

# Install required dependencies
RUN apt-get update
RUN apt-get install -y \
    pkg-config \
    libssl-dev \
    git \
    zip \
    libssh2-1-dev
RUN rm -rf /var/lib/apt/lists/*

# Install pueue for task management
RUN cargo install --locked pueue --version 3.4.1

# Set up workdir
WORKDIR /app

# Copy source code for the API and backend
COPY secret-contract-verifier-api /app/secret-contract-verifier-api
COPY secret-network-contract-verifier-backend /app/secret-network-contract-verifier-backend

# Build the API
WORKDIR /app/secret-contract-verifier-api
RUN cargo build --release

# Build the backend
WORKDIR /app/secret-network-contract-verifier-backend
RUN cargo build --release

# Create runtime image based on the same Debian image
FROM debian:bookworm-slim

# Install Docker
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    zip \
    bash
    
# Install Docker
RUN mkdir -m 0755 -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
RUN rm -rf /var/lib/apt/lists/*

# Copy built binaries from the builder stage
COPY --from=builder /app/secret-contract-verifier-api/target/release/secret_contract_verifier_api /usr/local/bin/
COPY --from=builder /app/secret-network-contract-verifier-backend/target/release/secret-contract-verifier /usr/local/bin/
COPY --from=builder /usr/local/cargo/bin/pueue /usr/local/bin/
COPY --from=builder /usr/local/cargo/bin/pueued /usr/local/bin/

# Copy necessary configuration files
COPY secret-contract-verifier-api/Rocket.toml /etc/rocket/Rocket.toml

# Create a directory for data persistence
RUN mkdir -p /data

# Set environment variables
# ENV MONGODB_URI="mongodb://192.168.1.42:27017/cometscan_demo"
ENV ROCKET_CONFIG="/etc/rocket/Rocket.toml"

# Create startup script
RUN printf '#!/bin/bash\n\
# Start Docker daemon\n\
dockerd &\n\
echo "Waiting for Docker daemon to start..."\n\
sleep 5\n\
\n\
# Start Pueue daemon\n\
pueued -d\n\
\n\
# Start the API\n\
secret_contract_verifier_api\n' > /usr/local/bin/start.sh

# Make it executable
RUN chmod +x /usr/local/bin/start.sh

# Verify the script exists and is executable
RUN ls -la /usr/local/bin/start.sh
RUN cat /usr/local/bin/start.sh

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/start.sh"] 