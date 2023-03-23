terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.21"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

data "coder_provisioner" "me" {
}

provider "docker" {
}

data "coder_workspace" "me" {
}

data "docker_registry_image" "image" {
  name = "ghcr.io/mxnet-dev/${var.image_version}"
}

resource "docker_image" "image" {
  name          = "${trim(data.docker_registry_image.image.name, "1234567890:")}@${data.docker_registry_image.image.sha256_digest}"
  pull_triggers = [data.docker_registry_image.image.sha256_digest]
  keep_locally  = true
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)
  EOF
  default     = "https://github.com/mxnet-dev/dotfiles"
}

variable "image_version" {
  type        = string
  description = <<-EOF
  Which version do you want to use for your workspace?

  EOF

  default = "ubuntu:2204"

  validation {
    condition     = contains(["ubuntu:2004","ubuntu:2204"], var.image_version)
    error_message = "Value must be ubuntu:2004, ubuntu:2204."
  }
}

resource "coder_agent" "main" {
  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
  }
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  dir            = "/home/coder"
  startup_script = <<EOF
  #!/bin/sh
  %{ if var.dotfiles_uri != "" }coder dotfiles -y ${var.dotfiles_uri}%{ endif }
  curl -fsSL https://code-server.dev/install.sh | sh
  code-server --auth none --port 13337 &
  EOF
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.main.id
  name     = "VSCode"
  icon     = "/icon/code.svg"
  url      = "http://localhost:13337/?folder=/home/coder"
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-root"
}

resource "docker_container" "workspace" {
  count   = data.coder_workspace.me.start_count
  image   = docker_image.image.image_id
  name    = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  dns     = ["1.1.1.1"]
  command = ["sh", "-c", replace(coder_agent.main.init_script, "127.0.0.1", "host.docker.internal")]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  host {
    host  = "host.docker.internal"
    ip    = "host-gateway"
  }
  volumes {
    container_path = "/home/coder/"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
}

resource "coder_metadata" "container_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id

  item {
    key   = "arch"
    value = coder_agent.main.arch
  }

  item {
    key   = "name"
    value = docker_container.workspace[0].name
  }

  item {
    key   = "version"
    value = var.image_version
  }
}

resource "coder_metadata" "image_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_image.image.id
  hide        = false

  item {
    key   = "image"
    value = docker_image.image.name
  }
}