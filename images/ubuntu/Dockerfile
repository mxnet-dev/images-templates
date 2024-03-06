FROM ubuntu:22.04

ARG TARGETARCH
ARG DOCKER_COMPOSE_VERSION=v2.24.7
ARG GITHUB_CLI_VERSION=v2.45.0
ARG GOTASK_VERSION=v3.35.1

SHELL ["/bin/bash", "-c"]

# Install the Docker apt repository
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get upgrade --yes && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes ca-certificates
RUN apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Add Ansible PPA
RUN apt-add-repository --yes --update ppa:ansible/ansible

# Add HashiCorp repository
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list

# Add Cloudflare repository
RUN mkdir -p --mode=0755 /usr/share/keyrings && \
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-main.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" > /etc/apt/sources.list.d/cloudflared.list

# Add the key for the 1Password Apt repository
RUN curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

# Add the 1Password Apt repository
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    tee /etc/apt/sources.list.d/1password.list

# Add the debsig-verify policy
RUN mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
    tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
    mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

# Install baseline packages
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
      ansible \
      ansible-lint \
      bash \
      build-essential \
      ca-certificates \
      cloudflared \
      containerd.io \
      curl \
      docker-ce \
      docker-ce-cli \
      docker-compose-plugin \
      git \
      htop \
      jq \
      locales \
      man \
      nano \
      openssh-client \
      1password-cli \
      python3-dev \
      python3 \
      python3-pip \
      python3-yaml \
      software-properties-common \
      sudo \
      systemd \
      systemd-sysv \
      terraform \
      packer \
      unzip \
      vim \
      wget \
      yamllint \
      zsh

# Install latest Git using their official PPA
RUN add-apt-repository ppa:git-core/ppa && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes git

# Install gotask and GitHub CLI
RUN wget -O /tmp/gotask.tar.gz https://github.com/go-task/task/releases/download/${GOTASK_VERSION}/task_linux_${TARGETARCH}.tar.gz && \
    tar -xzf /tmp/gotask.tar.gz -C /usr/local/bin && \
    rm /tmp/gotask.tar.gz && \
    wget -O - https://github.com/cli/cli/releases/download/${GITHUB_CLI_VERSION}/gh_$(echo "${GITHUB_CLI_VERSION}" | tr -d 'v')_linux_${TARGETARCH}.tar.gz | tar -xz -C /tmp && \
    mv /tmp/gh_$(echo "${GITHUB_CLI_VERSION}" | tr -d 'v')_linux_${TARGETARCH}/bin/gh /usr/local/bin/ && \
    rm -rf /tmp/gh_$(echo "${GITHUB_CLI_VERSION}" | tr -d 'v')_linux_${TARGETARCH}

# Enables Docker starting with systemd
RUN systemctl enable docker

# Add docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-${TARGETARCH}" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# Add a user `coder` so that you're not developing as the `root` user
RUN useradd coder \
      --create-home \
      --shell=/bin/bash \
      --groups=docker \
      --uid=1000 \
      --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder

# Install Homebrew on amd64 only
RUN if [ "${TARGETARCH}" = "amd64" ]; then \
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh > /tmp/install.sh && \
        /bin/bash /tmp/install.sh && \
        rm /tmp/install.sh && \
        echo 'PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.bashrc && \
        echo 'PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"' >> ~/.bashrc; \
    fi
