# lesson-4 — Django + PostgreSQL + Nginx у Docker

Багатосервісний проєкт, запущений через Docker Compose:

| Сервіс  | Образ                  | Призначення                                        |
|---------|------------------------|----------------------------------------------------|
| `web`   | збирається з `Dockerfile` (Python 3.12) | Django-застосунок на порту 8000 (лише всередині мережі) |
| `db`    | `postgres:17-alpine`   | База даних PostgreSQL, дані в томі `postgres_data` |
| `nginx` | `nginx:stable-alpine`  | Приймає запити на порту 80 і проксує їх у Django   |

## Структура

```
.
├── Dockerfile            # образ Django: python:3.12-slim + requirements.txt
├── docker-compose.yml    # сервіси web, db, nginx
├── entrypoint.sh         # застосовує міграції й запускає сервер
├── requirements.txt      # Django, psycopg
├── manage.py
├── config/               # налаштування Django (БД — PostgreSQL зі змінних оточення)
├── core/                 # застосунок: головна сторінка + модель Visit
└── nginx/nginx.conf      # proxy_pass http://django:8000
```

`nginx.conf` звертається до хоста `django`, тому в `docker-compose.yml` сервіс `web`
має мережевий псевдонім `django`.

## Запуск

```bash
docker compose up -d --build      # або docker-compose up -d --build
docker compose ps                 # усі три сервіси Up, db — healthy
```

Відкрийте http://localhost. Сторінка показує:

- що запит пройшов через Nginx;
- версію PostgreSQL, до якої підключився Django;
- лічильник відвідувань — кожне оновлення сторінки додає запис у таблицю PostgreSQL.

Адмінка: http://localhost/admin/ (користувача створити командою
`docker compose exec web python manage.py createsuperuser`).

## Налаштування

Без файлу `.env` використовуються значення за замовчуванням. Щоб змінити паролі:

```bash
cp .env.example .env
```

## Зупинка

```bash
docker compose down        # зупинити й видалити контейнери
docker compose down -v     # те саме + видалити дані PostgreSQL
```
