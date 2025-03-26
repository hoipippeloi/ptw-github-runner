#!/bin/bash
# Exit on error
set -e

# Check for required environment variables
if [ -z "$REPO_URL" ] || [ -z "$RUNNER_TOKEN" ]; then
    echo "Error: REPO_URL and RUNNER_TOKEN must be set."
    exit 1
fi

# Configure the runner
./config.sh --url "$REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --name "${RUNNER_NAME:-railway-runner}" \
    --work _work \
    --labels "${RUNNER_LABELS:-railway}" \
    --unattended

# Function to reconfigure the runner on error
reconfigure_runner() {
    echo "Attempting to reconfigure the runner..."
    ./config.sh remove --token "$RUNNER_TOKEN" --unattended
    ./config.sh --url "$REPO_URL" \
        --token "$RUNNER_TOKEN" \
        --name "${RUNNER_NAME:-railway-runner}" \
        --work _work \
        --labels "${RUNNER_LABELS:-railway}" \
        --unattended
}

# Run the runner in a loop, reconfiguring if necessary
while true; do
    ./run.sh &
    wait
    echo "Runner exited. Checking exit code."

    # Check the exit code. 1 and 2 are common errors that can be fixed by reconfiguring.
    if [ $? -eq 1 ] || [ $? -eq 2 ]; then
        reconfigure_runner
    else
        echo "Runner exited with an unrecoverable error. Exiting."
        exit 1
    fi

    echo "Restarting runner in 5 seconds..."
    sleep 5
done 