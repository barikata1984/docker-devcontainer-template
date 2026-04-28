# =============================================================================
# Development Container — Base Template
# =============================================================================
# Base: NVIDIA CUDA + Ubuntu 24.04
# Adds:  Python venv, GPU rendering libs, dev tooling, non-root user
#
# Build:  docker compose build
# Run:    docker compose up -d
# Attach: docker compose exec dev zsh
# =============================================================================

ARG CUDA_VERSION=12.8.0
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

# ---- System packages --------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        # Shell & terminal
        zsh \
        tmux \
        # VCS & build essentials
        git \
        git-lfs \
        curl \
        wget \
        unzip \
        build-essential \
        cmake \
        # Python 3
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        # GPU rendering (EGL / OSMesa for headless)
        libegl1 \
        libgl1 \
        libgles2 \
        libosmesa6-dev \
        libglfw3 \
        libglfw3-dev \
        # Editor (fallback)
        nano \
        vim \
        # Utilities
        sudo \
        gosu \
        locales \
        ca-certificates \
        openssh-client \
        less \
        jq \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ---- Python virtual environment ---------------------------------------------
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv ${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

# ---- Pip packages (from separate requirements file) -------------------------
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# ---- Non-root user (fixed UID/GID = 1000, name = uid1000) -------------------
# This image is pinned to UID/GID 1000 on purpose: bind-mounted files from a
# host whose primary account is UID=1000 will be owned by `uid1000` inside the
# container without any per-host build args.
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000
ARG CONTAINER_USER=uid1000

RUN if getent group ${CONTAINER_GID} >/dev/null 2>&1; then \
        existing_grp=$(getent group ${CONTAINER_GID} | cut -d: -f1); \
        [ "$existing_grp" != "${CONTAINER_USER}" ] && groupmod -n ${CONTAINER_USER} "$existing_grp"; \
    else \
        groupadd -g ${CONTAINER_GID} ${CONTAINER_USER}; \
    fi \
    && if getent passwd ${CONTAINER_UID} >/dev/null 2>&1; then \
         existing_usr=$(getent passwd ${CONTAINER_UID} | cut -d: -f1); \
         usermod -l ${CONTAINER_USER} -s /bin/zsh -g ${CONTAINER_GID} \
                 -d /home/${CONTAINER_USER} -m "$existing_usr"; \
       else \
         useradd -m -s /bin/zsh -u ${CONTAINER_UID} -g ${CONTAINER_GID} ${CONTAINER_USER}; \
       fi \
    && echo "${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL" \
       > /etc/sudoers.d/container-user \
    && chmod 0440 /etc/sudoers.d/container-user

# ---- Entrypoint -------------------------------------------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
