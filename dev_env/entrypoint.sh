#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${USER_NAME:-admin}"
USER_UID="${USER_UID:-1000}"
USER_GID="${USER_GID:-1000}"
SSH_PASS="${SSH_PASS:-admin123}"

mkdir -p /workspaces /data

if ! getent group "${USER_GID}" >/dev/null 2>&1; then
  groupadd -g "${USER_GID}" devgroup || true
fi

if ! id -u "${USER_NAME}" >/dev/null 2>&1; then
  useradd -m -u "${USER_UID}" -g "${USER_GID}" -s /bin/bash "${USER_NAME}"
  usermod -aG sudo "${USER_NAME}" || true
  echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers || true
fi

echo "${USER_NAME}:${SSH_PASS}" | chpasswd

if [ -S /var/run/docker.sock ]; then
  SOCK_GID="$(stat -c '%g' /var/run/docker.sock || true)"
  if [ -n "${SOCK_GID}" ]; then
    if ! getent group "${SOCK_GID}" >/dev/null 2>&1; then
      groupadd -g "${SOCK_GID}" dockersock || true
    fi
    usermod -aG "${SOCK_GID}" "${USER_NAME}" || true
  fi
fi

ssh-keygen -A >/dev/null 2>&1 || true

echo "[INFO] root python: $(/usr/local/bin/python --version 2>/dev/null || true)"
echo "[INFO] venv python: $(python --version 2>/dev/null || true)"
echo "[INFO] conda: $(conda --version 2>/dev/null || true)"
echo "[INFO] uv: $(uv --version 2>/dev/null || true)"
echo "[INFO] docker: $(docker --version 2>/dev/null || true)"

if ! grep -qs '/opt/conda/bin' /etc/environment 2>/dev/null; then
  echo 'PATH="/opt/venv/bin:/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' | sudo tee /etc/environment >/dev/null
fi

sudo tee /etc/profile.d/conda-init.sh >/dev/null <<'EOF'
__conda_setup="$('/opt/conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
  eval "$__conda_setup"
else
  if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
    . "/opt/conda/etc/profile.d/conda.sh"
  fi
fi
unset __conda_setup
EOF
sudo chmod 644 /etc/profile.d/conda-init.sh

sudo bash -lc 'grep -q "conda-init.sh" /etc/bash.bashrc || echo "source /etc/profile.d/conda-init.sh" >> /etc/bash.bashrc'

exec "$@"
