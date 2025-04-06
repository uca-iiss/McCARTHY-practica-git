terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "wp_network" {
  name = "wordpress_network"
}

resource "docker_volume" "db_data" {
  name = "mariadb_data"
}

resource "docker_container" "mariadb" {
  name  = "mariadb"
  image = "mariadb:latest"
  restart = "always"

  env = [
    "MYSQL_ROOT_PASSWORD=${var.db_root_password}",
    "MYSQL_DATABASE=${var.db_name}",
    "MYSQL_USER=${var.db_user}",
    "MYSQL_PASSWORD=${var.db_password}"
  ]

  networks_advanced {
    name = docker_network.wp_network.name
  }

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/mysql"
  }
}

resource "docker_container" "wordpress" {
  name  = "wordpress"
  image = "wordpress:latest"
  restart = "always"

  env = [
    "WORDPRESS_DB_HOST=mariadb",
    "WORDPRESS_DB_NAME=${var.db_name}",
    "WORDPRESS_DB_USER=${var.db_user}",
    "WORDPRESS_DB_PASSWORD=${var.db_password}"
  ]

  networks_advanced {
    name = docker_network.wp_network.name
  }

  ports {
    internal = 80
    external = 8080
  }
}
