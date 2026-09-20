# 1. Use lightweight official Python image
FROM python:3.12-slim

# 2. Set working directory inside container
WORKDIR /app

# 3. Copy requirements first for better layer caching
COPY requirements.txt .

# 4. Install dependencies without saving temp cache files
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the application source code
COPY . .

# 6. Create a non-root user and switch to it for security
RUN adduser --disabled-password --gecos "" appuser && \
    chown -R appuser:appuser /app
USER appuser

# 7. Expose Flask default port
EXPOSE 5000

# 8. Start the application
CMD ["python", "run.py"]