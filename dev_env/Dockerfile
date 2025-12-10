FROM python:3.13.7-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    CONDA_DIR=/opt/conda \
    VENV_DIR=/opt/venv \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git bash \
      openssh-server sudo \
      tini gosu \
      build-essential pkg-config \
      libffi-dev libssl-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ARG DOCKER_CLI_VER=27.3.1
RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VER}.tgz" \
  | tar -xz -C /tmp \
  && mv /tmp/docker/docker /usr/local/bin/docker \
  && rm -rf /tmp/docker \
  && docker --version

RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p "${CONDA_DIR}" \
    && rm /tmp/miniconda.sh \
    && "${CONDA_DIR}/bin/conda" config --system --set auto_activate_base false \
    && "${CONDA_DIR}/bin/conda" clean --all -y

ENV UV_INSTALL_DIR=/usr/local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && /usr/local/bin/uv --version \
    && /usr/local/bin/uvx --version || true

COPY requirements.txt /tmp/requirements.txt
RUN /usr/local/bin/uv venv "${VENV_DIR}" \
    && if [ -s /tmp/requirements.txt ]; then \
         /usr/local/bin/uv pip install --python "${VENV_DIR}/bin/python" -r /tmp/requirements.txt; \
       fi

ENV PATH="${VENV_DIR}/bin:${CONDA_DIR}/bin:/usr/local/bin:${PATH}"

RUN mkdir -p /var/run/sshd \
    && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config

RUN groupadd -g 1000 devgroup \
    && useradd -m -u 1000 -g 1000 -s /bin/bash admin \
    && usermod -aG sudo admin \
    && echo 'admin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p /workspaces /data \
    && chown -R admin:devgroup /workspaces /data /home/admin

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspaces
EXPOSE 22

ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd","-D"]
