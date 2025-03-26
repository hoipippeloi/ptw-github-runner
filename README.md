# GitHub Actions Runner on Railway

This repository contains a Docker-based GitHub Actions runner that can be deployed on Railway. It provides a self-hosted runner environment for executing GitHub Actions workflows.

## Features

- Based on the official GitHub Actions runner
- Automatic reconfiguration on token expiration
- Configurable runner labels
- Persistent runner identity
- Easy deployment on Railway
- Pre-configured Railway template with required variables

## Prerequisites

- A Railway account
- A GitHub repository where you want to use the runner
- GitHub repository admin access to generate runner tokens

## Setup Instructions

1. Fork this repository to your GitHub account

2. Create a new project on Railway and connect it to your forked repository

3. In your GitHub repository:
   - Go to Settings > Actions > Runners
   - Click "New self-hosted runner"
   - Copy the configuration token

4. Railway will automatically detect the required variables from the `railway.toml` file:
   - You'll be prompted to fill in `REPO_URL` and `RUNNER_TOKEN` before deployment
   - Optional variables (`RUNNER_NAME` and `RUNNER_LABELS`) have default values

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| REPO_URL | Yes | GitHub repository URL |
| RUNNER_TOKEN | Yes | GitHub Actions runner registration token |
| RUNNER_NAME | No | Custom name for the runner (default: railway-runner) |
| RUNNER_LABELS | No | Comma-separated list of labels (default: railway) |

## Railway Template Configuration

This repository includes a `railway.toml` file that configures:
- Required variables that must be set before deployment
- Default values for optional variables
- Build and deployment settings
- Health check configuration
- Restart policy

When deploying to Railway, you'll be prompted to fill in the required variables before the deployment can proceed.

## Usage

1. Deploy the runner on Railway
2. The runner will automatically register with your GitHub repository
3. Use the runner in your workflows by adding the appropriate label:

```yaml
jobs:
  build:
    runs-on: self-hosted
    # or use the railway label if you kept the default
    runs-on: railway
```

## Security Considerations

- Never commit the `RUNNER_TOKEN` to the repository
- Use Railway's environment variables for sensitive data
- Regularly rotate the runner token
- Monitor runner activity in GitHub

## Troubleshooting

If the runner stops working:
1. Check the Railway logs for error messages
2. Verify the environment variables are set correctly
3. Generate a new runner token in GitHub and update it in Railway
4. The runner will automatically reconfigure if needed

## License

MIT License - See LICENSE file for details 