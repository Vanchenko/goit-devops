#!/usr/bin/env bash
#
# install_dev_tools.sh
# Встановлює інструменти DevOps-інженера на Ubuntu / Debian:
#   - Docker Engine
#   - Docker Compose (v2, плагін "docker compose")
#   - Python 3.9+ і pip
#   - Django (через pip)
#
# Кожен інструмент встановлюється лише тоді, коли його ще немає в системі.
#
# Використання:
#   chmod u+x install_dev_tools.sh
#   ./install_dev_tools.sh

set -euo pipefail

readonly MIN_PYTHON_MAJOR=3
readonly MIN_PYTHON_MINOR=9

# ---------- Допоміжні функції ----------

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; RED=''; BLUE=''; NC=''
fi

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
skip()    { echo -e "${YELLOW}[SKIP]${NC} $*"; }
error()   { echo -e "${RED}[FAIL]${NC} $*" >&2; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Якщо скрипт запущено не від root — використовуємо sudo.
if [[ "${EUID}" -eq 0 ]]; then
    SUDO=""
else
    if ! command_exists sudo; then
        error "Потрібні права root або встановлений sudo."
        exit 1
    fi
    SUDO="sudo"
fi

APT_UPDATED=false
apt_update_once() {
    if [[ "${APT_UPDATED}" == false ]]; then
        info "Оновлюю список пакетів (apt-get update)..."
        ${SUDO} apt-get update -qq
        APT_UPDATED=true
    fi
}

apt_install() {
    apt_update_once
    ${SUDO} env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@"
}

# ---------- Перевірка ОС ----------

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Не вдалося визначити ОС (немає /etc/os-release)."
        exit 1
    fi
    # shellcheck source=/dev/null
    . /etc/os-release
    OS_ID="${ID}"
    OS_CODENAME="${VERSION_CODENAME:-}"

    case "${OS_ID}" in
        ubuntu|debian) info "Виявлено ОС: ${PRETTY_NAME}" ;;
        *)
            error "Скрипт підтримує лише Ubuntu / Debian (виявлено: ${OS_ID})."
            exit 1
            ;;
    esac
}

# ---------- Docker ----------

add_docker_repo() {
    local keyring="/etc/apt/keyrings/docker.asc"
    local list="/etc/apt/sources.list.d/docker.list"

    if [[ -f "${list}" ]]; then
        return 0
    fi

    info "Додаю офіційний apt-репозиторій Docker..."
    apt_install ca-certificates curl
    ${SUDO} install -m 0755 -d /etc/apt/keyrings
    ${SUDO} curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" -o "${keyring}"
    ${SUDO} chmod a+r "${keyring}"

    echo "deb [arch=$(dpkg --print-architecture) signed-by=${keyring}] \
https://download.docker.com/linux/${OS_ID} ${OS_CODENAME} stable" \
        | ${SUDO} tee "${list}" >/dev/null

    # Після додавання репозиторію список пакетів треба оновити ще раз.
    APT_UPDATED=false
}

install_docker() {
    if command_exists docker; then
        skip "Docker уже встановлено: $(docker --version)"
        return 0
    fi

    info "Встановлюю Docker..."
    add_docker_repo
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    # Запуск сервісу (якщо в системі є systemd).
    if command_exists systemctl && [[ -d /run/systemd/system ]]; then
        ${SUDO} systemctl enable --now docker >/dev/null 2>&1 || true
    fi

    # Дозволяємо поточному користувачу працювати з Docker без sudo.
    local target_user="${SUDO_USER:-${USER:-}}"
    if [[ -n "${target_user}" && "${target_user}" != "root" ]]; then
        ${SUDO} usermod -aG docker "${target_user}"
        info "Користувача ${target_user} додано до групи docker (діє після повторного входу)."
    fi

    success "Docker встановлено: $(docker --version)"
}

# ---------- Docker Compose ----------

install_docker_compose() {
    if docker compose version >/dev/null 2>&1; then
        skip "Docker Compose уже встановлено: $(docker compose version)"
        return 0
    fi
    if command_exists docker-compose; then
        skip "Docker Compose (standalone) уже встановлено: $(docker-compose --version)"
        return 0
    fi

    info "Встановлюю Docker Compose (плагін docker compose)..."
    add_docker_repo
    apt_install docker-compose-plugin

    success "Docker Compose встановлено: $(docker compose version)"
}

# ---------- Python ----------

# Повертає 0, якщо python3 є і його версія >= MIN_PYTHON_MAJOR.MIN_PYTHON_MINOR.
python_version_ok() {
    command_exists python3 || return 1
    python3 -c "import sys; sys.exit(0 if sys.version_info >= (${MIN_PYTHON_MAJOR}, ${MIN_PYTHON_MINOR}) else 1)"
}

install_python() {
    if python_version_ok; then
        skip "Python уже встановлено: $(python3 --version)"
    else
        info "Встановлюю Python ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}+..."
        apt_install python3
        if ! python_version_ok; then
            error "Версія python3 з репозиторію нижча за ${MIN_PYTHON_MAJOR}.${MIN_PYTHON_MINOR}: $(python3 --version 2>&1)."
            error "Оновіть дистрибутив (Ubuntu 22.04+ / Debian 11+) і запустіть скрипт знову."
            exit 1
        fi
        success "Python встановлено: $(python3 --version)"
    fi

    if python3 -m pip --version >/dev/null 2>&1; then
        skip "pip уже встановлено: $(python3 -m pip --version | cut -d' ' -f1-2)"
    else
        info "Встановлюю pip..."
        apt_install python3-pip
        success "pip встановлено: $(python3 -m pip --version | cut -d' ' -f1-2)"
    fi
}

# ---------- Django ----------

install_django() {
    if python3 -m django --version >/dev/null 2>&1; then
        skip "Django уже встановлено: $(python3 -m django --version)"
        return 0
    fi

    info "Встановлюю Django через pip..."
    local pip_args=(install --user --quiet django)

    # Ubuntu 23.04+ / Debian 12+ (PEP 668) забороняють pip-встановлення
    # у системний Python без цього прапорця.
    if python3 -m pip install --help 2>/dev/null | grep -q -- '--break-system-packages'; then
        local stdlib
        stdlib="$(python3 -c 'import sysconfig; print(sysconfig.get_path("stdlib"))')"
        if [[ -f "${stdlib}/EXTERNALLY-MANAGED" ]]; then
            pip_args+=(--break-system-packages)
        fi
    fi

    python3 -m pip "${pip_args[@]}"

    # pip --user кладе django-admin у ~/.local/bin — підказуємо додати в PATH.
    if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
        info "Додайте ~/.local/bin у PATH, щоб використовувати django-admin:"
        info "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
    fi

    success "Django встановлено: $(python3 -m django --version)"
}

# ---------- Main ----------

main() {
    info "=== Встановлення інструментів DevOps ==="
    check_os
    install_docker
    install_docker_compose
    install_python
    install_django

    echo
    success "=== Готово. Встановлені версії ==="
    echo "  Docker:         $(docker --version)"
    echo "  Docker Compose: $(docker compose version 2>/dev/null || docker-compose --version)"
    echo "  Python:         $(python3 --version)"
    echo "  pip:            $(python3 -m pip --version | cut -d' ' -f1-2)"
    echo "  Django:         $(python3 -m django --version)"
}

main "$@"
