FROM ubuntu:latest
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y
RUN apt-get install -y python-pip python-dev build-essential python-software-properties libssl-dev libffi-dev
COPY . /app
WORKDIR /app
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
CMD python -u app.py
