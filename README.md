# my_app

Rails 8 template with Docker, PostgreSQL, Redis, Sidekiq, and production-ready defaults.

## Stack

| Component | Version |
|---|---|
| Ruby | 3.3.6 |
| Rails | 8.0.x |
| PostgreSQL | 16 |
| Redis | 7 |
| Node.js | 20 LTS |
| Yarn | 1.22+ |
| Sidekiq | 7.x |

## Quick Start

```bash
git clone <repo> my_app
cd my_app
cp .env.example .env
```

Optional project rename:

```bash
bash scripts/rename_project.sh your_project_name
```

Start development environment:

```bash
docker compose up --build
```

App URL: `http://localhost:3000`  
Health: `http://localhost:3000/health`  
Mailpit UI: `http://localhost:8025`  
Sidekiq UI: `http://localhost:3000/sidekiq`

## Common Commands

Database:

```bash
docker compose run --rm rails rails db:prepare
docker compose run --rm rails rails db:migrate
docker compose run --rm rails rails db:rollback
docker compose run --rm rails rails db:seed
```

Rails CLI:

```bash
docker compose run --rm rails rails console
docker compose run --rm rails rails routes
docker compose run --rm rails rails generate model Article title:string body:text
```

Tests and quality:

```bash
docker compose run --rm rails bundle exec rspec
docker compose run --rm rails bundle exec rubocop
docker compose run --rm rails bundle exec brakeman
```

Logs and shell:

```bash
docker compose logs -f rails
docker compose logs -f sidekiq
docker compose exec rails bash
```

## Production Compose

Build and run:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml build
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
docker compose -f docker-compose.yml -f docker-compose.prod.yml run --rm rails rails db:migrate
```

Required production environment variables:

```bash
SECRET_KEY_BASE=<openssl rand -hex 64>
POSTGRES_USER=<secure_user>
POSTGRES_PASSWORD=<strong_password>
POSTGRES_DB=my_app_production
REDIS_PASSWORD=<redis_password>
REDIS_URL=redis://:<redis_password>@redis:6379/0
ALLOWED_HOSTS=yourdomain.com
SMTP_HOST=smtp.sendgrid.net
SMTP_PASSWORD=<api_key>
ACTIVE_STORAGE_SERVICE=amazon
SIDEKIQ_USERNAME=<sidekiq_user>
SIDEKIQ_PASSWORD=<sidekiq_password>
```

## Rename Script

The rename script updates `my_app` / `MyApp` references across the template.

```bash
bash scripts/rename_project.sh new_project_name
```

Optional flags:

```bash
bash scripts/rename_project.sh new_project_name --yes
bash scripts/rename_project.sh new_project_name --dry-run
```

## License

MIT
