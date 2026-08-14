# Stage 1: Build stage
FROM python:3.11-alpine AS builder

WORKDIR /app

# Install Flask into a isolated prefix
RUN pip install --no-cache-dir --prefix=/install flask>=3.0.0

# Stage 2: Final minimal runtime stage
FROM python:3.11-alpine

WORKDIR /app

# Copy only the installed dependencies from builder (excludes pip, setuptools, wheel artifacts)
COPY --from=builder /install /usr/local

# Remove default pip/setuptools from runtime to eliminate package manager CVEs
RUN rm -rf /usr/local/lib/python3.11/site-packages/setuptools* \
           /usr/local/lib/python3.11/site-packages/pip* \
           /usr/local/lib/python3.11/site-packages/wheel* \
           /usr/local/lib/python3.11/site-packages/msgpack* \
           /usr/local/lib/python3.11/site-packages/easy_install*

# Create non-root user
RUN adduser -D appuser && chown -R appuser /app
USER appuser

COPY --chown=appuser:appuser app.py .

EXPOSE 5000

CMD ["python", "app.py"]