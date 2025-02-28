# WorkHive

A contrived HTTP job processing service

### Agenda

- [Tech Stack](https://github.com/kyihtooag/work-hive#tech-stack)
- [Setup development environment](https://github.com/kyihtooag/work-hive#setup-development-environment)
- [Testing](https://github.com/kyihtooag/work-hive#testing)
- [API Endpoints](https://github.com/kyihtooag/work-hive#api-endpoints)
- [Deployment](https://github.com/kyihtooag/work-hive#deployment)

## Tech stack

Ensure the correct software versions are installed:

- Erlang 27.0
- Elixir 1.17.x
- Phoenix 1.7.x

## Setup development environment

Step 1: Clone the repository

```bash
git clone git@github.com:kyihtooag/work-hive.git
```

Step 2: Install and set up dependencies

```bash
mix setup
```

Step 4: Start the Phoenix server

```bash
mix phx.server

# or inside IEx for debugging
iex -S mix phx.server
```

Now you can make an API call to [`localhost:4000/api/tasks`](http://localhost:4000/api/tasks) from your browser.

## Testing

```bash
mix test
```

## API Endpoints

### POST `/api/tasks`

This endpoint accepts a POST request to accept a job, which is a collection of tasks. Each task has a name and a shell command and may depend on other tasks and require that those are executed beforehand. The API will take care of sorting the tasks to create a proper execution order.

#### Request Body

Here’s an request body JSON look like:

- `name`: (string) The name of the task.
- `command`: (string) The command of the task.
- `requires`: (array of strings) A list of tasks that need to be executed before the current task.

Example request body:

```json
{
  "tasks": [
    {
      "name": "task-1",
      "command": "cat /tmp/file1"
      "requires":["task-2"]
    },
    {
      "name": "task-2",
      "command": "touch /tmp/file1"
    }
  ]
}
```

#### Response

If the request is successful, the API will return a JSON object containing the sorted list of items based on their names.

Example response body:

```json
{
  "tasks": [
    {
      "name": "task-2",
      "command": "touch /tmp/file1"
    },
    {
      "name": "task-1",
      "command": "cat /tmp/file1"
    }
  ]
}
```

#### Additional Query Parameter

If you pass the query parameter `format=bash` in the request, the API will return a bash script representation of sorted commands.

Example request with the query parameter:

```bash
POST /api/todo?format=bash
```

Example response (plain text):

```bash
#!/usr/bin/env bash


touch /tmp/file1
cat /tmp/file1
```

This addition gives a clear explanation of how to use the `/api/todo` endpoint, including request format, response format, and an example of how to call it using cURL. Let me know if you need any further adjustments!

# Deployment

## Build the Docker Image

This project already includes a Dockerfile, which you can use to build the Docker image for the application.

### Build the Docker image:

To build the Docker image locally, run the following command from the root directory of the repository:

```bash
docker build -t work-hive-image .
```

## Run the Docker Container on a Production Server (e.g., EC2)

Once you've built the Docker image, you can push it to a Docker registry (e.g., Docker Hub), pull it on your production server, and run it.

#### 1. Tag and Push the Image to Docker Hub:

Tag the Docker image with your Docker Hub username:

```bash
docker tag work-hive-image your-dockerhub-username/work-hive-image:latest
```

Push the image to Docker Hub:

```bash
docker push your-dockerhub-username/work-hive-image:latest
```

#### 2. Pull the Image and Run it on your production server:

First, please make sure docker is installed on the server and your instance allows inbound traffic on port 4000.
Pull the image from Docker Hub:

```bash
docker pull your-dockerhub-username/work-hive-image:latest
```

Generate your SECRET_KEY_BASE by running `mix phx.gen.secret` in your local terminal.
After pulling the image, run the container with the following command:

```bash
docker run -d \
  --name work-hive-app \
  -e HOST=localhost \
  -e PORT=4000 \
  -e SECRET_KEY_BASE=your_generated_secret_key \
  -p 4000:4000 \
  your-dockerhub-username/work-hive-image:latest
```

This will run the container and map port 4000 on the EC2 instance to port 4000 in the container.

## Special Note: CI/CD Pipeline

This repository is configured with its own CI/CD pipeline that is triggered automatically when a new commit is pushed or a branch is merged into the main branch.

### Continuous Integration (CI)

- Runs tests to ensure functionality.
- Checks code formatting to maintain consistency.
- Verifies that the project compiles without warnings.

### Continuous Deployment (CD)

- Builds a Docker container image.
- Automatically deploys the Docker image to an EC2 server on AWS.

This will provide the instructions for building the Docker image, pushing it to Docker Hub, pulling it on an EC2 server, and running the Docker container.
Let me know if you'd like further tweaks!

## Learn more

- Learn more about Phoenix Framework: https://hexdocs.pm/phoenix/overview.html
- Deployment Guides with Release and Container: https://hexdocs.pm/phoenix/releases.html#containers
