# lesson-3 — Linux адміністрування

`install_dev_tools.sh` — Bash-скрипт, що встановлює на Ubuntu / Debian:

- Docker Engine (з офіційного репозиторію Docker);
- Docker Compose v2 (плагін `docker compose`);
- Python 3.9+ і pip;
- Django (через `pip`).

Перед встановленням кожного інструмента скрипт перевіряє, чи він уже є в системі, і пропускає його, якщо так.

## Запуск

```bash
chmod u+x install_dev_tools.sh
./install_dev_tools.sh
```

Скрипт запускається від звичайного користувача з правами `sudo` (або від root).
Після встановлення Docker перелогіньтесь, щоб працювати з `docker` без `sudo`.
