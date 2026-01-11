# Stage 1: Builder
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
# Install dependencies including dev for build (if any)
RUN npm ci

COPY . .

# Stage 2: Runner
FROM node:18-alpine AS runner

WORKDIR /app

# Install tini for signal handling
RUN apk add --no-cache tini

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy dependencies and code
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app .

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]
