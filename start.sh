#!/bin/bash
# Exit on error
set -e

# Enable debug logging
set -x

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check for required environment variables with more descriptive messages
if [ -z "$REPO_URL" ]; then
    log "Error: REPO_URL is not set. Please provide it in the Railway UI deployment variables."
    log "Format should be: https://github.com/owner/repo"
    exit 1
fi

if [ -z "$RUNNER_TOKEN" ]; then
    log "Error: RUNNER_TOKEN is not set. Please provide it in the Railway UI deployment variables."
    log "Get this token from GitHub repository Settings > Actions > Runners > New self-hosted runner"
    exit 1
fi

# Ensure we have write permissions
if [ ! -w "$(pwd)" ]; then
    log "Error: Current user does not have write permissions in the working directory."
    exit 1
fi

# Generate a unique runner name using timestamp and random string
if [ -z "$RUNNER_NAME" ]; then
    RUNNER_NAME="railway-runner-$(date +%s)-$(openssl rand -hex 4)"
    log "No custom RUNNER_NAME provided, using generated name: $RUNNER_NAME"
else
    log "Using custom RUNNER_NAME from Railway UI: $RUNNER_NAME"
fi

# Set default labels if not provided
if [ -z "$RUNNER_LABELS" ]; then
    RUNNER_LABELS="railway"
    log "No custom RUNNER_LABELS provided, using default: $RUNNER_LABELS"
else
    log "Using custom RUNNER_LABELS from Railway UI: $RUNNER_LABELS"
fi

# Validate REPO_URL format
if [[ ! "$REPO_URL" =~ ^https://github.com/[^/]+/[^/]+$ ]]; then
    log "Error: REPO_URL must be in the format https://github.com/owner/repo"
    log "Current value: $REPO_URL"
    log "Please update this in the Railway UI deployment variables"
    exit 1
fi

# Function to remove existing runner
remove_existing_runner() {
    log "Removing existing runner..."
    
    # Check if .runner and .credentials files exist before trying to remove
    if [ -f ".runner" ] && [ -f ".credentials" ]; then
        ./config.sh remove --token "$RUNNER_TOKEN" || true
    else
        log "Runner not registered, skipping removal"
    fi
}

# Function to configure the runner
configure_runner() {
    log "Configuring runner..."
    
    # Attempt configuration with retry logic
    ATTEMPT=1
    MAX_ATTEMPTS=3
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        log "Configuration attempt $ATTEMPT of $MAX_ATTEMPTS"
        
        if ./config.sh --url "$REPO_URL" \
            --token "$RUNNER_TOKEN" \
            --name "$RUNNER_NAME" \
            --work _work \
            --labels "$RUNNER_LABELS" \
            --unattended; then
            
            log "Runner successfully configured"
            return 0
        else
            CONFIG_EXIT=$?
            log "Configuration failed with exit code $CONFIG_EXIT"
            
            if [ $CONFIG_EXIT -eq 404 ]; then
                log "ERROR: Received 404 Not Found. This usually means:"
                log "1. The RUNNER_TOKEN has expired (they expire after 1 hour)"
                log "2. The REPO_URL is incorrect"
                log "Please update these values in the Railway UI deployment variables"
            fi
            
            if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
                log "Retrying in 10 seconds..."
                sleep 10
            fi
        fi
        
        ATTEMPT=$((ATTEMPT+1))
    done
    
    log "Failed to configure runner after $MAX_ATTEMPTS attempts"
    log "Please check the REPO_URL and RUNNER_TOKEN variables in the Railway UI"
    return 1
}

# Function to reconfigure the runner on error
reconfigure_runner() {
    log "Attempting to reconfigure the runner..."
    remove_existing_runner
    configure_runner
}

# Function to check runner status
check_runner_status() {
    if [ -f ".runner" ] && [ -f ".credentials" ]; then
        log "Runner configuration files exist"
        return 0
    else
        log "Runner configuration files not found"
        return 1
    fi
}

# Initial setup - with retry logic
MAX_INIT_ATTEMPTS=5
INIT_ATTEMPT=1

log "Starting GitHub Actions runner setup with Railway UI variables"
log "REPO_URL: $REPO_URL"
log "RUNNER_NAME: $RUNNER_NAME"
log "RUNNER_LABELS: $RUNNER_LABELS"

while [ $INIT_ATTEMPT -le $MAX_INIT_ATTEMPTS ]; do
    log "Initial setup attempt $INIT_ATTEMPT of $MAX_INIT_ATTEMPTS"
    
    remove_existing_runner
    
    if configure_runner; then
        log "Initial setup successful"
        break
    else
        if [ $INIT_ATTEMPT -eq $MAX_INIT_ATTEMPTS ]; then
            log "Failed to initialize runner after $MAX_INIT_ATTEMPTS attempts"
            log "Please check your REPO_URL and RUNNER_TOKEN variables in the Railway UI"
            log "REPO_URL: $REPO_URL"
            exit 1
        fi
        
        log "Retrying initial setup in 30 seconds..."
        sleep 30
        INIT_ATTEMPT=$((INIT_ATTEMPT+1))
    fi
done

# Run the runner in a loop, reconfiguring if necessary
RESTART_COUNT=0
MAX_RESTARTS=10

while [ $RESTART_COUNT -lt $MAX_RESTARTS ]; do
    log "Starting runner... (restart $RESTART_COUNT of $MAX_RESTARTS)"
    
    # Check if configuration files exist before starting
    if ! check_runner_status; then
        log "Runner not properly configured, reconfiguring..."
        if ! configure_runner; then
            log "Reconfiguration failed, exiting"
            log "Please check the variables in the Railway UI and redeploy"
            exit 1
        fi
    fi
    
    # Run the runner and capture exit code
    ./run.sh &
    RUNNER_PID=$!
    
    wait $RUNNER_PID
    EXIT_CODE=$?
    
    log "Runner exited with code $EXIT_CODE"
    
    # Handle different exit codes
    case $EXIT_CODE in
        0)
            log "Runner exited successfully"
            exit 0
            ;;
        1|2|143)
            log "Runner exited with recoverable error code $EXIT_CODE"
            reconfigure_runner
            ;;
        *)
            log "Runner exited with unrecoverable error code $EXIT_CODE"
            RESTART_COUNT=$((RESTART_COUNT+1))
            
            if [ $RESTART_COUNT -ge $MAX_RESTARTS ]; then
                log "Maximum restart attempts reached, exiting"
                log "Check Railway logs and update variables in the Railway UI if needed"
                exit 1
            fi
            ;;
    esac

    log "Restarting runner in 30 seconds..."
    sleep 30
done

log "Maximum runner restarts reached, exiting"
log "Please check the Railway UI logs and update variables if needed"
exit 1 