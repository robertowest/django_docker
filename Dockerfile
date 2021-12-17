FROM python:3.7

ENV PYTHONDONTWRITEBYTECODE 1
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

# creamos usuario 1000 para no tener problemas con los permisos
RUN useradd -ms /bin/bash usuario
RUN chown -R usuario:usuario /code
USER usuario
