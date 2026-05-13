# ---------- Etapa builder: compilar Angular ----------
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

# ---------- Etapa runtime: servir con Nginx ----------
FROM nginx:alpine AS runtime

RUN rm -rf /usr/share/nginx/html/* \
    && rm -f /etc/nginx/conf.d/default.conf

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /app/dist/casino-frontend/browser/. /usr/share/nginx/html/

RUN chown -R nginx:nginx /usr/share/nginx/html \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chown -R nginx:nginx /etc/nginx/conf.d \
    && chown -R nginx:nginx /etc/nginx/templates \
    && touch /var/run/nginx.pid \
    && chown nginx:nginx /var/run/nginx.pid

USER nginx
EXPOSE 80