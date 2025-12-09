FROM node:20-alpine

WORKDIR /app

# Install wget for healthcheck
RUN apk add --no-cache wget

# Install dependencies
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force

# Create non-root user
RUN addgroup -S webhook && \
    adduser -S -G webhook webhook

# Copy application
COPY --chown=webhook:webhook server.js ./

USER webhook

# Expose ports
EXPOSE 8080 9091

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=5s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Start server
CMD ["node", "server.js"]

