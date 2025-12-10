# Stage 1: Build
FROM node:20-alpine AS builder

LABEL maintainer="donation-app"
LABEL description="Donation App Backend"

WORKDIR /app

# Copy package files first (leverage cache)
COPY package*.json ./

# Install dependencies (production only)
RUN npm install --omit=dev && npm cache clean --force

# Stage 2: Production (Ephemeral & Minimal)
FROM node:20-alpine

LABEL maintainer="donation-app"

WORKDIR /app

# Copy from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy source code
COPY src ./src

# Set environment
ENV NODE_ENV=production

# Expose port
EXPOSE 5000

# Run as non-root user
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/api/health || exit 1

# Start application
CMD ["node", "src/index.js"]
