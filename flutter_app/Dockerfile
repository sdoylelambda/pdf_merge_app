# === Stage 1: Build Flutter web app ===
FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app
COPY . .
RUN flutter build web --release

# === Stage 2: Serve via Nginx ===
FROM nginx:stable-alpine

# Copy built Flutter web files
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Default command
CMD ["nginx", "-g", "daemon off;"]
