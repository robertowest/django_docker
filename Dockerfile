FROM python:3.7

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# directorio de trabajo
RUN mkdir /code
WORKDIR /code

# copiamos archivo desde al host a WORKDIR
COPY requirements.txt .

# creamos un usuario 1000 para no tener problemas con el usuario host
RUN useradd -ms /bin/bash usuario
RUN chown -R usuario:usuario /code
USER usuario

# actualizamos pip e instalamos requerimientos
RUN python -m pip install --upgrade pip
RUN pip install -r requirements.txt --no-warn-script-location
