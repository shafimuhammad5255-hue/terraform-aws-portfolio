# Hardened and lightweight Python Alpine base image
FROM python:3.11-alpine

WORKDIR /app

# Upgrade core build packaging tools to resolve CVEs, then install Flask
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir flask>=3.0.0

# Create a non-root user for security best practices
RUN adduser -D appuser && chown -R appuser /app
USER appuser

COPY --chown=appuser:appuser app.py .

EXPOSE 5000

CMD ["python", "app.py"]