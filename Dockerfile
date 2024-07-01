FROM python:3.8.19-slim-bullseye AS builder

COPY requirements.txt .

RUN apt-get update &&\
  apt-get install -y curl &&\
  apt-get clean

## ----------------------------------------------------------------
## Add venv
## ----------------------------------------------------------------
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

## ----------------------------------------------------------------
## Install python packages
## ----------------------------------------------------------------
RUN pip install --upgrade pip
RUN python3 -m pip install --upgrade pip \
 && python3 -m pip install -r requirements.txt

FROM python:3.8.19-slim-bullseye

## ----------------------------------------------------------------
## add user so we can run things as non-root
## ----------------------------------------------------------------
RUN adduser flaskuser

## ----------------------------------------------------------------
## Copy from builder and set ENV for venv
## ----------------------------------------------------------------
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /service/app
COPY application /service/app/application

EXPOSE 8081

ENV PYTHONUNBUFFERED=1

HEALTHCHECK --timeout=30s --interval=1m30s --retries=5 \
  CMD curl -s --fail http://localhost:8081/health || exit 1

USER flaskuser
CMD ["python3", "-u", "application/app.py"]
