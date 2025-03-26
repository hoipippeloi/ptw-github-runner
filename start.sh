#!/bin/bash
# Exit on error
set -e

# Enable debug logging
set -x

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check for required environment variables
if [ -z "$REPO_URL" ] || [ -z "$RUNNER_TOKEN" ]; then
    log "Error: REPO_URL and RUNNER_TOKEN must be set."
    exit 1
fi

# Ensure we have write permissions
if [ ! -w "$(pwd)" ]; then
    log "Error: Current user does not have write permissions in the working directory."
    exit 1
fi

# Generate a unique runner name using timestamp and random string
RUNNER_NAME="${RUNNER_NAME:-railway-runner-$(date +%s)-$(openssl rand -hex 4)}"
log "Using runner name: $RUNNER_NAME"

# Function to remove existing runner
remove_existing_runner() {
    log "Removing existing runner..."
    ./config.sh remove --token "$RUNNER_TOKEN" --unattended || true
}

# Function to configure the runner
configure_runner() {
    log "Configuring runner..."
    ./config.sh --url "$REPO_URL" \
        --token "$RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --work _work \
        --labels "${RUNNER_LABELS:-railway}" \
        --unattended
}

# Function to reconfigure the runner on error
reconfigure_runner() {
    log "Attempting to reconfigure the runner..."
    remove_existing_runner
    configure_runner
}

# Function to check runner status
check_runner_status() {
    if [ -f ".runner" ]; then
        log "Runner configuration file exists"
        return 0
    else
        log "Runner configuration file not found"
        return 1
    fi
}

# Initial setup
remove_existing_runner
configure_runner

# Run the runner in a loop, reconfiguring if necessary
while true; do
    log "Starting runner..."
    ./run.sh &
    RUNNER_PID=$!
    
    wait $RUNNER_PID
    EXIT_CODE=$?
    
    log "Runner exited with code $EXIT_CODE"
    
    # Check the exit code. 1 and 2 are common errors that can be fixed by reconfiguring.
    if [ $EXIT_CODE -eq 1 ] || [ $EXIT_CODE -eq 2 ]; then
        log "Runner exited with reconfigurable error code"
        reconfigure_runner
    else
        log "Runner exited with unrecoverable error code"
        exit 1
    fi

    log "Restarting runner in 5 seconds..."
    sleep 5
done 