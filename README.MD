# Phober

![Laravel](https://img.shields.io/badge/Laravel-v9.2-red)

## Table of Contents

- [Technologies](#technologies)
- [Introduction](#introduction)
  - [Adminpanel](#p-aligncenteradminpanelp)
  - [Config Server](#p-aligncenterconfig-serverp)
  - [Notification Server](#p-aligncenternotification-serverp)
  - [Device Service](#p-aligncenterdevice-servicep)
  - [Auth Server](#p-aligncenterauth-serverp)
  - [API Gateway](#p-aligncenterapi-gatewayp)
  - [Media](#p-aligncentermediap)
- [Installation](#installation)
- [Usage](#usage)

## Technologies

- Laravel v9.2
- PHP v8.0
- MySQL
- Docker & Docker Compose

## Introduction

### <p align="center">Adminpanel</p>

The `adminpanel` service within the `phober` project is crucial for managing administrative tasks, user interfaces, and updating various databases and configurations. It interacts with the following databases:

- **`phober_adminpanel`**: Stores administrative data related to the admin panel interface.
- **`phober_auth`**: Manages authentication and authorization data.
- **`phober_device`**: Stores data related to device/game management.
- **`phober_media`**: Handles media files and storage for the application.
- **`phober_crm`**: Manages CRM customer data.
- **`phober_staff`**: Stores game/session/invoice data related to staff or user accounts.
- **`phober_notification`**: Manages notification data for the application.
- **`phober_config`**: Stores configuration data, managed by `config-server`
- **`phober_log`**: Stores logs and diagnostic information for the application.

#### Responsibilities:
- Manages administrative tasks, user interfaces, and updates databases and configurations.
- Updates configurations within `config-server`.
- Manages credentials required by `notification-server`.

#### Dependencies:
- Relies on the `db` service for database operations.

#### Framework and Initialization / Additional Requirements:
- Built using the Laravel framework.
- Requires PHP dependencies installed via Composer.
- Requires seeding the database with initial data.
- Utilizes an `auth.json` file for downloading dependencies such as `laravel/nova`.

### <p align="center">Config-server</p>

The `config-server` service within the `phober` project serves as a repository dedicated to storing configuration data crucial for the application's operation.

#### Responsibilities:
- Stores essential configuration data required for various aspects of the application.
- Centralizes configuration management to ensure consistency and accessibility across services.
- Provides an endpoint (`{app}/config-client/update`) and CLI command (`config-client:update`) for updating configuration settings.

#### Features:
- **CLI Command (`config-client:update`)**:
    - Executes configuration updates across services.
    - Supports variables such as `--dry-run` (simulate update process) and `--overwrite` (overwrite existing configurations).

- **HTTP Route (`{app}/config-client/update`)**:
    - Allows configuration updates via HTTP requests.
    - Supports query parameters such as `dry-run` (simulate update process if set to `'true'` default: `'false'`) and `overwrite` (overwrite existing configurations if set to `'true'` default: `'false'`).

#### Dependencies:
- Relies on the `adminpanel` service for updating and managing configuration data.

#### Additional Details:
- Utilizes the `laravel-config-server-client` package (available at [GitHub](https://github.com/Abdukhaligov/laravel-config-server-client) and [Packagist](https://packagist.org/packages/abdukhaligov/laravel-config-server-client)) for configuration management commands.
- Configuration values are retrieved from `.env` files, Docker environment variables, or the `phober_config` database managed by the `adminpanel`.

### <p align="center">Notification-server</p>

The `notification-server` service within the `phober` project manages the sending of various notifications such as emails, OTPs, and support messages. It integrates with communication platforms like Discord and Telegram. This service also includes a `notification-queue` component in Docker Compose, enabling asynchronous message handling through job queues to optimize responsiveness.

#### Responsibilities:
- Sends emails, OTPs, and support messages via Discord, Telegram, etc.
- Utilizes a `notification-queue` to manage message delivery asynchronously, optimizing performance and responsiveness.

#### Dependencies:
- Depends on the `config-server` and `adminpanel` services for configuration and data management.
- Utilizes the `phober_notification` database for data operations.

#### Environment Variables

The following environment variables can be configured via the `.env` file inside the notification-server directory or provided through Docker Compose:

 - `DISCORD_TOKEN`: The token for authenticating with the Discord API.
 - `DISCORD_SUPPORT_CHANNEL`: The channel ID for support messages in Discord.
 - `DISCORD_OTP_CHANNEL`: The channel ID for OTP messages in Discord.
 - `TELEGRAM_BOT_TOKEN`: The token for authenticating with the Telegram Bot API.
 - `TELEGRAM_OTP_CHANNEL`: The channel ID for OTP messages in Telegram.
 - `TELEGRAM_SUPPORT_CHANNEL`: The channel ID for support messages in Telegram.

#### Additional Details:
- Enhances message delivery efficiency using job queues within the Docker environment.
- Integrates with various communication platforms for versatile notification capabilities.

### <p align="center">Device-service</p>

The `device-service` within the `phober` project focuses on displaying hardware-related data, device configurations, and game information.

#### Responsibilities:
- Displays hardware data, device configurations, and game information.
- Does not manage data or configurations but serves as a viewer.

#### Dependencies:
- Relies on the `config-server` and `adminpanel` services for initial setup and configuration.
- Utilizes the `phober_device` database for data access.

#### Additional Details:
- Utilizes multiple instances (`replicas: 3`) for redundancy but does not function as a load balancer.
- Provides an interface to view hardware-related data within the application environment.

### <p align="center">Auth-server</p>

The `auth-server` within the `phober` project manages authentication and authorization functionalities using the `phober_auth` database for user authentication.

#### Responsibilities:
- Handles user authentication and authorization processes.
- Utilizes the `phober_auth` database for user authentication.

#### Dependencies:
- Relies on the `config-server` and `adminpanel` services for configuration and integration.

#### Additional Details:
- Facilitates secure user authentication and authorization within the application environment.


Certainly! Here's how you can structure the `Api-Gateway` section in your README file to include responsibilities, dependencies, and additional details:

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
    cp notification-server/.env.example notification-server/.env
    cp auth-server/.env.example auth-server/.env
    ```

4. Ensure you have the `auth.json` file configured in your project directory:
    ```bash
    cp auth.json.example auth.json
    ```

    ```json
    {
        "github-oauth": {
            "github.com": "github_pat_***"
        }
    }
    ```

   You can create this file by copying the `auth.json.example` template provided in the project directory and then adding your GitHub credentials.
   <br/>
   <br/>
   For guidance on creating a GitHub personal access token, refer to [this guide](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token).
   <br/>
   <br/>
   ***Note:*** This is required to download the `laravel/nova` package.


5. Build and start the Docker containers using the startup configuration:
    ```bash
    docker-compose -f docker-compose-startup.yml up -d
    ```

   This step initializes the Docker containers according to the startup configuration. It automatically performs the following tasks:

   - Runs `composer install` to install PHP dependencies for all services.
   - Executes `php artisan migrate --seed` for the `adminpanel` service, seeding the database with initial data.
    
   <br/>
   After this step, you'll have the core dependencies installed and your database populated with initial data for the adminpanel.


6. Generate the application keys for the `config-server` and `adminpanel`:
    ```bash
    docker-compose exec config-server php artisan key:generate
    docker-compose exec adminpanel php artisan key:generate
    ```

   **Note:** The `config-server` is a microservice where dynamic environment values are stored. These values can come from Docker environment variables, `.env` file, or the database, with the database having the highest priority.


7. Run the `config-client:update` command for specific services:
    ```bash
    docker-compose exec notification-server php /var/www/html/artisan config-client:update
    docker-compose exec auth-server php /var/www/html/artisan config-client:update
    docker-compose exec device-service php /var/www/html/artisan config-client:update
    ```

   This command updates each service's configuration based on dynamic values from the `config-server`.


8. Run the `storage:link` command for the adminpanel and device-service:
    ```bash
    docker-compose exec adminpanel php artisan storage:link
    docker-compose exec device-service php artisan storage:link
    ```

9. Shut down all Docker containers after the initial setup:
    ```bash
    docker-compose down
    ```

10. Start the full application stack:
    ```bash
    docker-compose up -d
    ```

    ***Note:*** Some containers like `api-gateway` and `config-server` or `notification-server` might not run sometimes. If this happens, try to start them by running this command again:

## Usage
