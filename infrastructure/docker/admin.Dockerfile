# S14 Part 29. Not build-verified in this sandbox (no privileged Docker
# daemon available here — see build-session-14.md's Docker section) but
# follows the same standard multi-stage pattern already used by
# api.Dockerfile: a build stage with the full toolchain, a minimal
# runtime stage with nothing else in it.

FROM node:20-alpine AS base
RUN corepack enable
WORKDIR /workspace

# ---- build: install the workspace, build the Vite static bundle.
FROM base AS build
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY apps/admin/package.json apps/admin/package.json
RUN pnpm install --frozen-lockfile
COPY apps/admin apps/admin

# VITE_API_BASE_URL must be provided at build time — see
# apps/admin/src/config/apiConfigValidation.ts, which makes the built
# bundle refuse to render the real app without it (never falls back to
# localhost, which would be meaningless for anyone but the machine that
# built the image). There is deliberately no default here, mirroring
# api.Dockerfile never baking in a default JWT secret.
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
RUN pnpm --filter @project-ascend/admin build

# ---- runtime: nginx serving nothing but the static build output.
# nginxinc/nginx-unprivileged (not plain nginx:alpine) so the container
# never runs as root at any point, matching api.Dockerfile's runtime
# stage — its master process binds port 8080 (a port >1024, unlike 80)
# so it never needs the root privileges a stock nginx image's master
# process does.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime
COPY infrastructure/docker/nginx-admin.conf /etc/nginx/conf.d/default.conf
COPY --from=build /workspace/apps/admin/dist /usr/share/nginx/html
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
  CMD wget -qO- --spider http://127.0.0.1:8080/ || exit 1
