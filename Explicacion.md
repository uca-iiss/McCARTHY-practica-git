# Explicación de los archivos `docker-compose.yml`

En este documento vamos a explicar la configuración de los archivos `docker-compose.yml` utilizados para desplegar **Drupal** con **MySQL** y **WordPress** con **MariaDB** utilizando Docker Compose.

---

## **Archivo **``** (Drupal + MySQL)**

### **1. Definición de Servicios**

```yaml
version: '3.8'

services:
  drupal:
    image: drupal:latest
    container_name: drupal
    ports:
      - "81:80"
    depends_on:
      - db
    environment:
      - DRUPAL_DB_HOST=db
      - DRUPAL_DB_USER=drupal
      - DRUPAL_DB_PASSWORD=drupal
      - DRUPAL_DB_NAME=drupal
    volumes:
      - drupal_data:/var/www/html

  db:
    image: mysql:5.7
    container_name: drupal_db
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_DATABASE=drupal
      - MYSQL_USER=drupal
      - MYSQL_PASSWORD=drupal
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  drupal_data:
  mysql_data:
```

### **2. Explicación de la Configuración**

- **Drupal**:

  - Se utiliza la imagen oficial `drupal:latest`.
  - Se asigna el contenedor con el nombre `drupal`.
  - Se expone el puerto `81` del host al puerto `80` del contenedor.
  - La opción `depends_on` garantiza que el servicio `db` se inicie antes.
  - Se configuran variables de entorno para la conexión a la base de datos.
  - Se asigna un volumen `drupal_data` para persistencia de datos.

- **MySQL**:

  - Se utiliza la imagen `mysql:5.7`.
  - Se asigna el contenedor con el nombre `drupal_db`.
  - Se configura la base de datos, usuario y contraseña a través de variables de entorno.
  - Se asigna un volumen `mysql_data` para persistencia de datos.

- **Red**:

  - Se usa la red por defecto de Docker con driver `bridge`.
  - Los contenedores pueden comunicarse usando el nombre del servicio (`db`).

---

## **Archivo **``** (WordPress + MariaDB)**

### **1. Definición de Servicios**

```yaml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    ports:
      - "82:80"
    networks:
      - redDocker
    environment:
      - WORDPRESS_DB_HOST=mariadb:3306
      - WORDPRESS_DB_NAME=wordpress
      - WORDPRESS_DB_USER=wordpressuser
      - WORDPRESS_DB_PASSWORD=wordpresspassword
    volumes:
      - wordpress_data:/var/www/html

  mariadb:
    image: mariadb:latest
    container_name: mariadb
    networks:
      - redDocker
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpressuser
      - MYSQL_PASSWORD=wordpresspassword
    volumes:
      - mariadb_data:/var/lib/mysql

networks:
  redDocker:
    driver: bridge

volumes:
  wordpress_data:
  mariadb_data:
```

### **2. Explicación de la Configuración**

- **WordPress**:

  - Se utiliza la imagen oficial `wordpress:latest`.
  - Se asigna el contenedor con el nombre `wordpress`.
  - Se expone el puerto `82` del host al puerto `80` del contenedor.
  - Se configura la conexión con la base de datos a través de variables de entorno.
  - Se asigna un volumen `wordpress_data` para persistencia.
  - Se conecta a la red `redDocker`.

- **MariaDB**:

  - Se utiliza la imagen oficial `mariadb:latest`.
  - Se asigna el contenedor con el nombre `mariadb`.
  - Se configura la base de datos, usuario y contraseña a través de variables de entorno.
  - Se asigna un volumen `mariadb_data` para persistencia.
  - Se conecta a la red `redDocker`.

- **Red**:

  - Se define una red personalizada llamada `redDocker` con driver `bridge`.
  - Los contenedores pueden comunicarse entre ellos usando el nombre del servicio (`mariadb`).



