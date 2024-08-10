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

3. Copy the `.env.example` file to `.env` in each submodule directory:
    ```bash
    cp adminpanel/.env.example adminpanel/.env
    cp config-server/.env.example config-server/.env
    cp device-service/.env.example device-service/.env
    cp crm-service/.env.example crm-service/.env
    cp notification-server/.env.example notification-server/.env
    cp auth-server/.env.example auth-server/.env
    ```

4. Ensure you have the `auth.json` file configured in your `adminpanel` directory:
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


5. Build and start the Docker containers using the startup configuration:
    ```bash
    docker-compose -f docker-compose-startup.yml up -d
    ```

   <details>
      <summary>Notes</summary>

      This step initializes the Docker containers according to the startup configuration and automatically runs composer install to install PHP dependencies for all services.

      Run the command without the `-d` flag initially to monitor the logs and ensure everything is running smoothly. Once you have verified that the setup is working as expected, you can run the command in detached mode:

      After this step, you'll have the core dependencies installed and your database populated with initial data for the adminpanel.
   </details>


6. Generate the application keys for the `config-server` and `adminpanel`:
    ```bash
    docker-compose exec config-server php artisan key:generate
    docker-compose exec adminpanel php artisan key:generate
    ```
   <details>
      <summary>Notes</summary>

      The `config-server` is a microservice where dynamic environment values are stored. These values can come from Docker environment variables, `.env` file, or the database, with the database having the highest priority.
   </details>


7. Initialize Database Tables and Seed Initial Data for `adminpanel`:

    ```bash
    docker-compose exec adminpanel php artisan migrate --seed
    ```

8. Run the `config-client:update` command for specific services:
    ```bash
    docker-compose exec notification-server php /var/www/html/artisan config-client:update --custom-env-file=.env.shared
    docker-compose exec auth-server php /var/www/html/artisan config-client:update --custom-env-file=.env.shared
    docker-compose exec device-service php /var/www/html/artisan config-client:update --custom-env-file=.env.shared
    docker-compose exec crm-service php /var/www/html/artisan config-client:update --custom-env-file=.env.shared
    ```

   <details>
      <summary>Notes</summary>

      This command updates each service's configuration based on dynamic values from the `config-server`.
   </details>


9. Run the `storage:link` command for the adminpanel and device-service:
    ```bash
    docker-compose exec adminpanel php artisan storage:link
    docker-compose exec device-service php artisan storage:link
    ```

10. Shut down all Docker containers after the initial setup and before start the full application stack:
    ```bash
    docker-compose down
    docker-compose up -d
    ```

## Postman Collection

<p>To help you get started with the <b>Phober</b> project, I've prepared a Postman collection that includes all the necessary API endpoints. This collection will allow you to easily test and interact with the different microservices within the project.</p>

<p>The collection is organized by service, with each folder representing a different microservice. Inside each folder, you'll find all the relevant API endpoints along with example requests and responses.</p>

***Note:*** Make sure to set the `{{baseUrl}}` variable in your Postman environment to point to the `api-gateway` URL, as it serves as the base URL for all the endpoints.

[Phober.postman_collection.json](Phober.postman_collection.json)
