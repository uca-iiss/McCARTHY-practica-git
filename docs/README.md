# Despliegue de Jenkins + Docker-in-Docker usando Terraform

En este documento vamos a explicar paso a paso cómo replicar el proceso de despliegue, desde la construcción de la imagen personalizada de Jenkins hasta la configuración del pipeline para lanzar la aplicación.

---

## 1. Crear la imagen personalizada de Jenkins

Primero crea un archivo `Dockerfile` con el siguiente contenido:

```dockerfile
#Utilizamos la imagen oficial de Jenkins como base 
FROM jenkins/jenkins:lts

#Cambiamos al usuario root para poder instalas software dentro del contenedor ya que el usuario jenkins por defecto no puede
USER root

# Instalar Docker CLI en Jenkins
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli

USER jenkins

# Plugins para usar Docker y BlueOcean
RUN jenkins-plugin-cli --plugins "docker-workflow blueocean"

```

Luego, construye la imagen:

```bash
docker build -t custom-jenkins .
```

---

## 2. Desplegar los contenedores con Terraform

Crea un archivo `main.tf` con la siguiente configuración:

```hcl
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


```

Para desplegar:

```bash
terraform init
terraform apply
```

Confirma escribiendo `yes` cuando lo solicite.

---

## 3. Acceder a Jenkins

- Accede a Jenkins desde tu navegador en: [http://localhost:8080](http://localhost:8080)
- Te pedira una contraseña, para ello debes acceder a los logs donde estara la contraseña que necesitas:

```bash
docker logs <id del contenedor de jenkins>
```

Copia la contraseña y pégala en la pantalla de desbloqueo.

---

## 4. Configurar Jenkins

- Finaliza la instalación usando los **plugins sugeridos**.
- Crea tu **primer usuario administrador**.

---

## 5. Crear el Pipeline

1. Crea un nuevo **Pipeline** en Jenkins en el botón de arriba a la derecha donde pone **Nueva tarea**.
2. En **Pipeline script from SCM**:
   - SCM: **Git**
   - URL: `https://github.com/Chrisbayy/simple-node-js-react-npm-app`
   - Branch: `main`
3. El repositorio debe tener un `Jenkinsfile` con el siguiente contenido:

```groovy
pipeline {
    agent none
    stages {
        stage('Build') {
            agent {
                docker {
                    image 'python:2-alpine'
                }
            }
            steps {
                sh 'python -m py_compile sources/add2vals.py sources/calc.py'
            }
        }
        stage('Keep Alive') {
            agent {
                docker {
                    image 'python:2-alpine'
                }
            }
            steps {
                echo 'Manteniendo el contenedor activo...'
                sh 'tail -f /dev/null'
            }
        }
    }
}
```
4. Hemos añadido al Jenkinsfile del tutorial una nueva tarea para que se mantenga abierto el contenedor y asi poder probarlo desde la terminal.
---

## 6. Ejecutar Pipeline

Por último ejecutamos el pipeline y podremos ver como se lanza el contenedor.

---

## 7. Requisitos

- Docker instalado.
- Terraform instalado.
- Git instalado.
- Al menos 5 GB de espacio libre en disco (Importante ya que me ha causado mas de un dolor de cabeza).

---
