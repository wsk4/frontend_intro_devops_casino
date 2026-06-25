#Etapa 1: builder — compilar Angular 
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN if [ -f package-lock.json ]; then \
      npm ci; \
    else \
      echo ">>> AVISO: sin package-lock.json, usando npm install"; \
      npm install; \
    fi
COPY . .
RUN npm run build

# Etapa 2: runtime — nginx-unprivileged (no-root, puerto 8080) 
FROM nginxinc/nginx-unprivileged:alpine AS runtime

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /app/dist/casino-frontend/browser/. /usr/share/nginx/html/

EXPOSE 8080