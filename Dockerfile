FROM python:3.9-slim-bullseye as base

ENV PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1

WORKDIR /app

FROM base as builder

ENV PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VERSION=1.1.12

# Create a /venv directory & environment.
# This directory will be copied into the final stage of docker build.
RUN python -m venv /venv

# Copy only the necessary files to build/install the python package
COPY pyproject.toml poetry.lock /app/
COPY crawler_server /app/crawler_server

# Working directory is /app
# Use pip to install the mwmbl python package
# PEP 518, PEP 517 and others have allowed for a standardized python packaging API, which allows
# pip to be able to install poetry packages.
RUN /venv/bin/pip install pip --upgrade && \
    /venv/bin/pip install .

FROM base as final

# Copy only the required /venv directory from the builder image that contains mwmbl and its dependencies
COPY --from=builder /venv /venv

# Working directory is /app
# Run the server with Uvicorn
CMD ["/venv/bin/uvicorn", "--host", "0.0.0.0", "--port", "8080", "crawler_server.app:app"]
