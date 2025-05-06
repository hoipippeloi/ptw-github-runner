# GitHub Actions Self-Hosted Runner for Railway

This repository contains a Docker-based GitHub Actions runner that can be deployed to Railway.app. The runner automatically registers with your GitHub repository and can execute GitHub Actions workflows.

## Prerequisites

1. A GitHub repository where you want to use self-hosted runners
2. A Railway.app account

## Setup Instructions

### Step 1: Generate a GitHub Runner Token

1. Go to your GitHub repository
2. Navigate to Settings > Actions > Runners
3. Click "New self-hosted runner"
4. Make note of the repository URL and runner token shown in the instructions
   - URL format: `https://github.com/owner/repo`
   - Token format: `AXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`

> **IMPORTANT**: Runner tokens expire after 1 hour. If you don't use the token within that time, you'll need to generate a new one.

### Step 2: Deploy to Railway

1. Click the "Deploy to Railway" button (if available) or create a new service from this repository
2. You'll see a deployment form in the Railway UI with required variables to fill in:
   - `REPO_URL`: Your GitHub repository URL (e.g., `https://github.com/owner/repo`)
   - `RUNNER_TOKEN`: The registration token from Step 1

   ![Railway Deployment Form](https://docs.railway.app/assets/deploy-variables.png)

3. Optional variables will also be shown in the form:
   - `RUNNER_LABELS`: Custom labels for your runner (default: `railway`)
   - `RUNNER_NAME`: Custom name for your runner (default: auto-generated)

4. Click "Deploy" to start the deployment process once all required fields are filled

### Step 3: Verify Runner Registration

1. After deployment, check the service logs in Railway to verify registration was successful
2. In your GitHub repository, go to Settings > Actions > Runners to confirm the runner appears online

## Troubleshooting

### Runner Registration Failed (404 Not Found)

If you see a 404 error during registration, check the following:

1. **Token expired**: GitHub runner tokens expire after 1 hour. Generate a new token and update the `RUNNER_TOKEN` environment variable in the Railway dashboard.

2. **Incorrect URL format**: The `REPO_URL` must be in the format `https://github.com/owner/repo`.

3. **Permission issues**: Ensure you have admin access to the repository.

### Runner Goes Offline Frequently

The runner container includes retry logic, but if your runner goes offline frequently:

1. Check the Railway logs for specific error messages
2. Consider increasing Railway's resources for the service
3. Update the `RUNNER_TOKEN` if it's been a long time since deployment

## Using Your Self-Hosted Runner

In your GitHub workflow files (`.github/workflows/*.yml`), specify your self-hosted runner:

```yaml
jobs:
  build:
    runs-on: [self-hosted, railway]  # Use both "self-hosted" and your custom label
    steps:
      - uses: actions/checkout@v3
      # ...other steps
```

## Maintenance

- **Updating the runner**: The runner version is defined in the Dockerfile. To update, change the `RUNNER_VERSION` environment variable and redeploy.
- **Removing the runner**: To permanently remove the runner, delete the Railway service and go to GitHub repository settings to remove the offline runner.
- **Updating environment variables**: You can update any environment variable in the Railway dashboard under your service's Variables tab.

## Railway UI Features

Railway provides a user-friendly interface for managing your deployment:

- **Variables management**: Easily update environment variables through the UI
- **Logs viewer**: Monitor your runner's logs in real-time
- **Resource allocation**: Adjust CPU and memory allocation as needed
- **Restart controls**: Restart your service if needed

## Security Considerations

Self-hosted runners have access to the repository's secrets. Be mindful of the following security considerations:

1. Only use self-hosted runners with private repositories you trust
2. Consider using dedicated GitHub accounts with limited permissions
3. Regularly update the runner image to get security patches

## License

[MIT License](LICENSE) 