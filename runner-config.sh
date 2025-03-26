# Generate runner name with human-readable timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUNNER_NAME="railway-runner-${TIMESTAMP}"

log "Using runner name: ${RUNNER_NAME}"

remove_existing_runner() {
    log "Removing existing runner..."
    # Remove the --unattended flag for the remove command
    ./config.sh remove --token "${RUNNER_TOKEN}"
}

configure_runner() {
    log "Configuring runner..."
    # Keep the --unattended flag for configuration
    ./config.sh --url "${GITHUB_URL}" \
                --token "${RUNNER_TOKEN}" \
                --name "${RUNNER_NAME}" \
                --work "_work" \
                --labels railway \
                --unattended
} 