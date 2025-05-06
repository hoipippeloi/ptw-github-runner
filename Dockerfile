FROM ubuntu:latest

# Update and install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    git \
    openssl \
    sudo \
    # Playwright dependencies
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libatspi2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    libgtk-3-0 \
    # Node.js
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Set up required environment variables
ENV RUNNER_VERSION=2.311.0
ENV RUNNER_ARCH=x64
ENV RUNNER_HOME=/opt/actions-runner
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache

# Create a non-root user
RUN useradd -m -d ${RUNNER_HOME} runner \
    && chown -R runner:runner ${RUNNER_HOME}

# Add runner user to sudoers with NOPASSWD option
RUN echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure password for root user (empty password)
RUN passwd -d root

# Configure PAM to allow su without password
RUN echo "auth sufficient pam_permit.so" > /etc/pam.d/su

# Create the runner and toolcache directories with correct permissions
RUN mkdir -p ${RUNNER_HOME} \
    && mkdir -p ${AGENT_TOOLSDIRECTORY} \
    && chown -R runner:runner ${AGENT_TOOLSDIRECTORY} \
    && chmod -R 755 ${AGENT_TOOLSDIRECTORY}

# Download and extract the runner package
RUN curl -sSL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" -o actions-runner.tar.gz \
    && tar xzf actions-runner.tar.gz -C ${RUNNER_HOME} \
    && rm actions-runner.tar.gz \
    && chown -R runner:runner ${RUNNER_HOME}

# Copy the startup script
COPY start.sh ${RUNNER_HOME}/start.sh

# Make the startup script executable
RUN chmod +x ${RUNNER_HOME}/start.sh \
    && chown runner:runner ${RUNNER_HOME}/start.sh

# Set the working directory
WORKDIR ${RUNNER_HOME}

# Create log directory with proper permissions
RUN mkdir -p ${RUNNER_HOME}/logs \
    && chown -R runner:runner ${RUNNER_HOME}/logs

# Install Playwright as runner user
USER runner
RUN npm init -y && \
    npm install playwright && \
    npx playwright install --with-deps && \
    npm rm playwright

# Switch to non-root user
USER runner

# Define the entry point
ENTRYPOINT ["./start.sh"] 