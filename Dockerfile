# Stage 1: Build stage
FROM python:3.12.14-slim-bookworm AS builder

WORKDIR /build

# Install temporary build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user gunicorn -r requirements.txt

# Stage 2: Clean runtime stage
FROM python:3.12.14-slim-bookworm AS runner

# Create dedicated non-root user with home directory (-m)
RUN groupadd -g 10001 appgroup && \
    useradd -m -u 10001 -g appgroup -s /sbin/nologin appuser

WORKDIR /app

# Copy installed Python dependencies from builder
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appgroup . /app

# Ensure appuser owns its home folder
RUN chown -R appuser:appgroup /home/appuser

ENV PATH="/home/appuser/.local/bin:$PATH"
ENV HOME="/home/appuser"
ENV PYTHONUNBUFFERED=1

USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')" || exit 1

# Production WSGI server startup
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "run:app"]