# Stage 1: Build stage
FROM python:3.12.14-slim-bookworm AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Clean runtime stage
FROM python:3.12.14-slim-bookworm AS runner

RUN groupadd -g 10001 appgroup && \
    useradd -m -u 10001 -g appgroup -s /sbin/nologin appuser

WORKDIR /app

# Copy binaries to system PATH (/usr/local/bin) so home dir mounts won't shadow them
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY --chown=appuser:appgroup . /app
RUN chown -R appuser:appgroup /home/appuser

ENV PYTHONUNBUFFERED=1
ENV HOME="/home/appuser"

USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "run:app"]