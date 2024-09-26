## Table of Contents

- [Technologies](#technologies)
- [Introduction](#introduction)
  - [API Gateway](#api-gateway)
  - [Media](#media)
- [Installation](#installation)
- [Postman Collection](#postman-collection)

## Technologies

- Laravel v9.2
- PHP v8.0
- MySQL
- Docker & Docker Compose

## Introduction

<p>Welcome to the <b>Phober</b> project! This repository contains multiple microservices, each responsible for different aspects of the application. To understand each submodule deeply, please refer to their respective README files located in their directories.</p>

* Tasks for this project are managed using Trello. You can view the project board here.
* Private notes for the project are managed using Milanote.
* The architecture of the project is drawn using draw.io. These diagrams are pushed to the GitHub repository and can be found [here](https://github.com/phobiavr/phober-diagram).

### <p align="center">API Gateway</p>

The `Api-Gateway` simplifies client-side interactions by providing a single entry point to access multiple backend services. It abstracts the complexity of service locations and configurations, enhancing application scalability and management.

**Routing Structure**: The `Api-Gateway` routes requests to different microservices based on the URL path:
- `/notification/`: Routes to the notification server (`notification-server`).
- `/auth/`: Routes to the authentication server (`auth-server`).
- `/hardware/`: Routes to the device service (`device-service`).

**Note:** Refer to the provided Nginx configuration file (`env/api-gateway/nginx.conf`) for detailed setup and routing rules.

### <p align="center">Media</p>

The `Media` folder within our repository serves as a centralized repository for storing and managing files, similar to an S3 bucket but located locally. It plays a crucial role in our application for organizing and accessing media files efficiently.

The folder is configured with the `spatie/medialibrary` package, facilitating seamless file management operations directly within our application. This setup allows us to handle various media types and integrate them into different parts of our service architecture.

### Usage Across Services

- **Adminpanel:** Utilizes the `Media` folder for managing and storing files. It has full read-write access to the folder, enabling comprehensive file management capabilities.

- **Device-service:** Accesses the `Media` folder in a read-only mode. This service retrieves and displays media files managed by the `Adminpanel` without modifying them.

## Installation

### Prerequisites

- Docker and Docker Compose installed on your machine

### Steps

1. Clone the repository with all submodules:
    ```bash
    git clone --recurse-submodules --remote-submodules https://github.com/phobiavr/phober.git
    cd phober
    ```

2. Update and initialize submodules:
    ```bash
    git submodule update --init --recursive
    git submodule update --remote --merge
    ```

3. Ensure you have the `auth.json` file configured in your `adminpanel` directory:
    ```bash
    cp adminpanel/auth.json.example adminpanel/auth.json
    ```

    ```json
    {
        "github-oauth": {
            "github.com": "github_pat_***"
        }
    }
    ```

   <details>
      <summary>Notes</summary>

      This is required to download the `laravel/nova` package.

      You can create this file by copying the `auth.json.example` template provided in the project directory and then adding your GitHub credentials.

      For guidance on creating a GitHub personal access token, refer to [this guide](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token).
   </details>


4. Build and start the Docker containers:
    ```bash
    docker-compose up -d
    ```

## Postman Collection

<p>To help you get started with the <b>Phober</b> project, I've prepared a Postman collection that includes all the necessary API endpoints. This collection will allow you to easily test and interact with the different microservices within the project.</p>

<p>The collection is organized by service, with each folder representing a different microservice. Inside each folder, you'll find all the relevant API endpoints along with example requests and responses.</p>

***Note:*** Make sure to set the `{{baseUrl}}` variable in your Postman environment to point to the `api-gateway` URL, as it serves as the base URL for all the endpoints.

[Phober.postman_collection.json](Phober.postman_collection.json)
