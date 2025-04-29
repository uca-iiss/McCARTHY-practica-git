//Configuramos terraform y el proveedor Docker que vamos a utilizar
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

//Creamos una imagen Docker llamada custom-jenkins la cual ya habremos creado previamente en mi sistema local
resource "docker_image" "jenkins" {
  name         = "custom-jenkins"
  keep_locally = true
}

//Creamos un contenedor jenkins a partir de la imagen custom-jenkins
resource "docker_container" "jenkins" {
  name  = "jenkins"
  image = docker_image.jenkins.name

//Con esto hacemos que Jenkins se ejecute como root para que pueda acceder al socket de Docker
  user = "root"

//Aqui asignamos el puerto por el que podremos acceder a jenkins
  ports {
    internal = 8080
    external = 8080
  }
  //Montamos el socket docker dentro del contenedor para poder ejecutar comandos docker dentro de jenkins
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
}

//Aqui descargamos la imagen oficial de Docker in Docker
resource "docker_image" "dind" {
  name         = "docker:dind"
  keep_locally = false
}

//Lanzamos un contenedor de Docker in Docker
resource "docker_container" "dind" {
  name       = "docker-in-docker"
  image      = docker_image.dind.name
  privileged = true
}
