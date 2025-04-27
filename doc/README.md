# Despliegue de Jenkins + Docker-in-Docker usando Terraform

En este documento vamos a explicar paso a paso cómo replicar el proceso de despliegue, desde la construcción de la imagen personalizada de Jenkins hasta la configuración del pipeline.

---

## 1. Crear la imagen personalizada de Jenkins

Primero crea un archivo `Dockerfile` con el siguiente contenido:

```dockerfile
FROM jenkins/jenkins
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"
```

Luego, construye la imagen:

```bash
docker build -t custom-jenkins .
```

---

## 2. Desplegar los contenedores con Terraform

Crea un archivo `main.tf` con la siguiente configuración:

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "jenkins" {
  name         = "jenkins-custome"
  keep_locally = false
}

resource "docker_container" "jenkins" {
  name  = "jenkins"
  image = docker_image.jenkins.name
  ports {
    internal = 8080
    external = 8080
  }
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
}

resource "docker_image" "dind" {
  name         = "docker:dind"
  keep_locally = false
}

resource "docker_container" "dind" {
  name        = "docker-in-docker"
  image       = docker_image.dind.name
  privileged  = true
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
- Asegúrate de que Jenkins puede acceder al Docker daemon (`/var/run/docker.sock`).
- Verifica que tienes instalado el plugin **Docker Pipeline**.

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
    agent any

    stages {
        stage('Clone repository') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker image') {
            steps {
                sh 'docker build -t myapp:latest .'
            }
        }
        stage('Run Docker container') {
            steps {
                sh 'docker run -d -p 3000:3000 myapp:latest'
            }
        }
    }
}
```
4. Además debemos crear en el main un dockerfile con el cual le diremos como debe ser la aplicacion que se lance

```groovy
# Usa una imagen oficial de Node
FROM node:18

# Crea un directorio de trabajo
WORKDIR /usr/src/app

# Copia el package.json y package-lock.json
COPY package*.json ./

# Instala dependencias
RUN npm install

# Copia el resto del código
COPY . .

# Expone el puerto que usa la app
EXPOSE 3000

# Comando para lanzar la app
CMD ["npm", "start"]
```
---

## 6. Notas importantes

- Si ves errores de permisos, asegúrate que Jenkins puede usar `/var/run/docker.sock`, en caso contrario dale permisos para ello.
- Si necesitas limpiar todo para empezar de nuevo (que a veces hace falta):

```bash
docker system prune -a --volumes -f
```

---

## 7. Requisitos

- Docker instalado.
- Terraform instalado.
- Git instalado.
- Al menos 5 GB de espacio libre en disco (Importante ya que me ha causado mas de un dolor de cabeza).

---
