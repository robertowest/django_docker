# ¿Cómo ejecutar Django con Docker?

Lo primero que haremos será crear una carpeta donde guardaremos todo el proyecto, para este ejemplo crearemos una carpeta llamada _django_docker_.

```bash
mkdir django_docker
cd django_docker
```

Lo siguiente es crear el archivo _requirements.txt_ para posteriormente decirle que librerías queremos instalar, en este ejemplo, instalaremos lo básico, Django y psycopg2 (para conectar a Postgres).

```bash
nano requirements.txt
```

```text
django==3.2.7
psycopg2==2.7.7
```

Ahora vamos a crear un archivo Dockerfile sobre un contenedor basado en Python 3. En él crearemos un directorio llamado code y le diremos que es el directorio de trabajo, después copiaremos el archivo requirements.txt en el contenedor y utilizaremos pip para instalar las librerías que usaremos.

```bash
nano Dockerfile
```

```text
# Dockerfile
FROM python:3.7-slim
ENV PYTHONUNBUFFERED 1

# instalacion de paquetes (--no-install-recommends)
RUN apt-get update && apt-get install -y nano
RUN rm -rf /var/lib/apt/lists/*

# habilito los alias que utilizo
RUN sed -i \
        -e 's!# export LS_OPTIONS=!export LS_OPTIONS=!' \
        -e 's!# alias ls=!alias ls=!' \
        -e 's!# alias ll=!alias ll=!' \
        -e 's!# alias l=!alias l=!' \
        /root/.bashrc

# directorio de trabajo
RUN mkdir /code
WORKDIR /code

# actualizamos pip e instalamos requerimientos
COPY requirements.txt /code/
RUN python -m pip install --upgrade pip
RUN pip install -r requirements.txt
COPY . /code/
```

Ahora que ya tenemos esta parte, vamos a crear una carpeta llamada `.envs` y dentro de ella un archivo llamado `.postgres` donde guardaremos nuestras variables de entorno que se utilizarán más adelante en el contenedor de postgres:

```bash
mkdir .envs
nano .envs/.postgres
```

```text
# PostgreSQL
POSTGRES_HOST=db
POSTGRES_PORT=5432
POSTGRES_DB=djangoDB
POSTGRES_USER=usuario
POSTGRES_PASSWORD=usuario
```

Ya tenemos lista toda la configuración, ahora nos toca crear el archivo _docker-compose.yml_

**NOTA**: recomiendo utilizar docker separados, uno para postgres y otro para django

```bash
nano docker-compose.yml
```

```text
version: '3'

services:
  db:
    image: postgres
    env_file:
      - ./.envs/.postgres
    volumes:
      - ./postgres/data:/var/lib/postgresql/data      
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    env_file:
      - ./.envs/.postgres
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    depends_on:
      - db
```

En el servicio db en volumes le hemos dicho que queremos montar nuestra carpeta en _./postgres/data_ (deberéis crearla previamente) con la carpeta del contenedor de postgres que es _/var/lib/postgresql/data_ y es donde se almacenan todos los datos generados en postgres, de esta manera aunque paremos el contenedor seguiremos manteniendo los cambios.

```bash
mkdir -p ./postgres/data
```

Una vez hecho esto crearemos el proyecto con la siguiente orden, sustituir [nombre-proyecto] por el nombre que le queráis poner. Yo suelo crear la carpeta de proyecto y siempre llamo **config** a la carpeta que contiene el directorio inicial de django (donde se almacena _settings.py_).

```bash
docker-compose run web django-admin startproject [nombre-proyecto] .
```

Para finalizar la construcción del contenedor lanzaremos la ordern build

```bash
docker-compose build
```

Ahora que ya tenemos el proyecto creado, modificaremos el archivo _settings.py_ del proyecto de Django, para ello en nuestra carpeta raíz, buscamos en _[nombre-proyecto]/settings.py_ y realizamos las siguientes modificaciones para poder comunicarnos con nuestra base de datos.

```text
import os     # agregamos en la primera línea

ALLOWED_HOSTS = ['*']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ['POSTGRES_DB'],
        'USER': os.environ['POSTGRES_USER'],
        'PASSWORD': os.environ['POSTGRES_PASSWORD'],
        'HOST': os.environ['POSTGRES_HOST'],
        'PORT': os.environ['POSTGRES_PORT'],
    }
}

# al final del archivo agregomos estas líneas
AUTH_PASSWORD_VALIDATORS = []
LANGUAGE_CODE = 'es'
TIME_ZONE = 'America/Argentina/Tucuman'
```

Con esto ya estaría todo listo..., lanzamos el servicio y ya deberíamos tener nuestro proyecto funcionando.

```bash
docker-compose up
```

Solo nos queda acceder desde aquí http://localhost:8000


Para comprobar que podemos acceder al admin de Django haremos el _makemigrations_ y _migrate_ para crear las tablas en la base de datos, para ello ahora lo tendremos que lanzar de esta forma:

```bash
docker-compose run --rm web python manage.py makemigrations
docker-compose run --rm web python manage.py migrate
```

Y ahora crearemos el super usuario para poder entrar al panel con la siguiente orden:

```bash
docker-compose run --rm web python manage.py createsuperuser --username admin --email admin@correo.com
```

Levantamos nuevamente nuestro contenedor `docker-compose up` y accedemos a http://localhost:8000/admin y comprobamos que podemos realizar el login sin problema.

