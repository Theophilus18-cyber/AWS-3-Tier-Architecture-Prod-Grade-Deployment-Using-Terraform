# Stage 1: Build
FROM node:20-alpine AS builder

LABEL maintainer="donation-app"
LABEL description="Donation App Frontend"

WORKDIR /app

# Copy package files first (leverage cache)
COPY package*.json ./

# Install dependencies (no lockfile present)
RUN npm install

# Copy source code
COPY . .

# Build application
RUN npm run build

# Stage 2: Serve with nginx (Ephemeral & Minimal)
FROM nginx:alpine

LABEL maintainer="donation-app"

# Copy build artifacts
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
