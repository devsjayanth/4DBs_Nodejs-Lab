# ═══════════════════════════════════════════════════════════
#  4_DB-Lab — Single multi-stage Dockerfile
#
#  Stage 1  deps   Install production Node dependencies
#  Stage 2  api    Node.js API server  (target: api)
#  Stage 3  web    nginx static + proxy (target: web)
#
#  Build both with docker compose up --build
# ═══════════════════════════════════════════════════════════

# ── Stage 1: dependency installer ───────────────────────
FROM node:20-alpine AS deps
WORKDIR /build
COPY backend/package*.json ./
RUN npm install --omit=dev

# ── Stage 2: Node.js API ─────────────────────────────────
FROM node:20-alpine AS api
LABEL maintainer="Dev Jayanth" \
      description="4_DB-Lab — Node.js API"

WORKDIR /app

COPY --from=deps /build/node_modules ./node_modules
COPY backend/ ./

# Run as non-root
RUN addgroup -S 4dblab && adduser -S 4dblab -G 4dblab
USER 4dblab

EXPOSE 7010

HEALTHCHECK --interval=15s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:7010/api/status || exit 1

CMD ["node", "server.js"]

# ── Stage 3: nginx frontend ───────────────────────────────
FROM nginx:1.27-alpine AS web
LABEL maintainer="Dev Jayanth" \
      description="4_DB-Lab — nginx frontend"

# Remove default site config
RUN rm /etc/nginx/conf.d/default.conf

# nginx config and frontend live together in frontend/
COPY frontend/nginx.conf   /etc/nginx/conf.d/4db.conf
COPY frontend/index.html   /usr/share/nginx/html/index.html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1