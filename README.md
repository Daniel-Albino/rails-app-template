# my_app

Template base Rails 8 com Docker, PostgreSQL, Redis e Sidekiq.  
Pronto a usar em desenvolvimento e produção.

---

## Stack

| Componente | Versão |
|---|---|
| Ruby | 3.3.6 |
| Rails | 8.0.x |
| PostgreSQL | 16 |
| Redis | 7 |
| Node.js | 20 LTS |
| Yarn | 1.22+ |
| Sidekiq | 7.x |

---

## Estrutura do Projecto

```
my_app/
├── Dockerfile                          # Multi-stage: base / dependencies / development / production
├── docker-compose.yml                  # Orquestração para desenvolvimento
├── docker-compose.prod.yml             # Override para produção
├── .dockerignore                       # Exclusões do build context
├── .env.example                        # Template de variáveis de ambiente
├── .gitignore
├── .rubocop.yml                        # Linting Ruby
├── .rspec                              # Configuração RSpec
├── Gemfile                             # Dependências Ruby
├── package.json                        # Dependências Node
├── Procfile.dev                        # Processos dev sem Docker
│
├── docker/
│   ├── entrypoints/
│   │   └── entrypoint.sh              # Entrypoint principal do container
│   ├── scripts/
│   │   └── install-system-dependencies.sh
│   ├── environments/
│   │   ├── development.env            # Vars de desenvolvimento
│   │   └── production.env             # Vars de produção
│   ├── nginx/
│   │   └── conf.d/
│   │       └── my_app.conf            # Nginx reverse proxy (produção)
│   └── postgres/
│       └── init/                      # Scripts SQL de inicialização (opcional)
│
├── scripts/
│   └── rename_project.sh              # Renomeia o projecto
│
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── health_controller.rb       # GET /health
│   ├── models/
│   │   └── application_record.rb
│   ├── jobs/
│   │   └── application_job.rb
│   ├── mailers/
│   │   └── application_mailer.rb
│   ├── channels/
│   │   └── application_cable/
│   ├── javascript/
│   │   ├── application.js
│   │   └── controllers/               # Stimulus controllers
│   ├── assets/
│   │   └── stylesheets/
│   │       └── application.css
│   └── views/
│       └── layouts/
│           └── application.html.erb
│
├── config/
│   ├── application.rb
│   ├── boot.rb
│   ├── environment.rb
│   ├── routes.rb
│   ├── puma.rb
│   ├── cable.yml
│   ├── database.yml
│   ├── importmap.rb
│   ├── sidekiq.yml
│   ├── storage.yml
│   ├── environments/
│   │   ├── development.rb
│   │   ├── production.rb
│   │   └── test.rb
│   └── initializers/
│       └── sidekiq.rb
│
├── db/
│   ├── schema.rb
│   └── seeds.rb
│
└── spec/
    ├── spec_helper.rb
    ├── rails_helper.rb
    └── factories/
```

---

## Início Rápido

### 1. Clonar e configurar

```bash
# Clona o template
git clone <repo> my_app
cd my_app

# Cria o ficheiro de variáveis de ambiente
cp .env.example .env

# (Opcional) Renomeia o projecto
bash scripts/rename_project.sh nome_do_teu_projecto
```

### 2. Iniciar em desenvolvimento

```bash
# Constrói e inicia todos os serviços
docker compose up --build

# Em background
docker compose up --build -d
```

A aplicação fica disponível em **http://localhost:3000**  
Health check: **http://localhost:3000/health**  
Mailpit (email UI): **http://localhost:8025**  
Sidekiq Web UI: **http://localhost:3000/sidekiq**

---

## Comandos Docker Essenciais

### Base de dados

```bash
# Prepara a DB (cria + migrations + schema) — primeira vez
docker compose run --rm web rails db:prepare

# Corre apenas migrations pendentes
docker compose run --rm web rails db:migrate

# Rollback da última migration
docker compose run --rm web rails db:rollback

# Reset completo (apaga e recria)
docker compose run --rm web rails db:reset

# Carrega seeds
docker compose run --rm web rails db:seed
```

### Rails CLI

```bash
# Console interactivo Rails
docker compose run --rm web rails console

# Gerar um model
docker compose run --rm web rails generate model Article title:string body:text

# Gerar um controller
docker compose run --rm web rails generate controller Articles index show

# Gerar uma migration
docker compose run --rm web rails generate migration AddSlugToArticles slug:string:uniq

# Ver todas as rotas
docker compose run --rm web rails routes

# Verificar estado das migrations
docker compose run --rm web rails db:migrate:status
```

### Testes

```bash
# Correr toda a suite de testes
docker compose run --rm web bundle exec rspec

# Correr um ficheiro específico
docker compose run --rm web bundle exec rspec spec/models/article_spec.rb

# Correr com coverage
docker compose run --rm web bundle exec rspec --format progress

# Linting
docker compose run --rm web bundle exec rubocop

# Análise de segurança
docker compose run --rm web bundle exec brakeman
```

### Gems e dependências

```bash
# Instalar novas gems (após editar Gemfile)
docker compose run --rm web bundle install

# Actualizar todas as gems
docker compose run --rm web bundle update

# Actualizar uma gem específica
docker compose run --rm web bundle update rails

# Instalar dependências Node (após editar package.json)
docker compose run --rm web yarn install
```

### Logs e debugging

```bash
# Ver logs de todos os serviços
docker compose logs -f

# Ver logs apenas do Rails
docker compose logs -f web

# Aceder ao shell do container
docker compose exec web bash

# Ver processos a correr
docker compose ps
```

### Gestão dos serviços

```bash
# Parar todos os serviços (mantém volumes)
docker compose down

# Parar e apagar volumes (reset total)
docker compose down -v

# Reconstruir apenas o container web
docker compose up --build web

# Reiniciar um serviço específico
docker compose restart web
```

---

## Produção

### Deploy com docker-compose

```bash
# Build da imagem de produção
docker compose -f docker-compose.yml -f docker-compose.prod.yml build

# Iniciar em produção
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Correr migrations em produção
docker compose -f docker-compose.yml -f docker-compose.prod.yml \
  run --rm web rails db:migrate

# Ver logs em produção
docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f web
```

### Variáveis obrigatórias em produção

Edita o ficheiro `.env` com valores reais:

```bash
SECRET_KEY_BASE=<gera com: openssl rand -hex 64>
POSTGRES_USER=<utilizador_seguro>
POSTGRES_PASSWORD=<password_forte>
POSTGRES_DB=my_app_production
REDIS_PASSWORD=<password_redis>
ALLOWED_HOSTS=teudominio.com
SMTP_HOST=smtp.sendgrid.net
SMTP_PASSWORD=<api_key>
```

---

## Renomear o Projecto

Para usar este template num novo projecto:

```bash
bash scripts/rename_project.sh nome_do_novo_projecto
```

O script substitui automaticamente todas as referências a `my_app` / `MyApp` pelo novo nome, incluindo:
- `docker-compose.yml`
- `Dockerfile`
- `config/application.rb`
- `config/database.yml`
- `package.json`, `Gemfile`
- Todos os ficheiros Ruby em `app/` e `config/`

---

## Serviços e Portas

| Serviço | URL / Porta | Descrição |
|---|---|---|
| Rails | http://localhost:3000 | Aplicação principal |
| PostgreSQL | localhost:5432 | Base de dados |
| Redis | localhost:6379 | Cache e jobs |
| Mailpit SMTP | localhost:1025 | Servidor SMTP dev |
| Mailpit UI | http://localhost:8025 | Preview de emails |
| Sidekiq UI | http://localhost:3000/sidekiq | Dashboard de jobs |

---

## Licença

MIT
