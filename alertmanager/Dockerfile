FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir requests prometheus-client

# Create non-root user
RUN useradd -m -u 1000 webhook && \
    chown -R webhook:webhook /app

USER webhook

# Copy webhook server
COPY --chown=webhook:webhook webhook-server.py /app/webhook-server.py
RUN chmod +x /app/webhook-server.py

# Expose port
EXPOSE 8080

# Use webhook server as entrypoint
ENTRYPOINT ["python3", "/app/webhook-server.py"]

