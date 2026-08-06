FROM node:20-alpine AS base
RUN corepack enable
WORKDIR /workspace

# ---- build: install the full workspace (incl. devDependencies, needed for
# the Prisma CLI and the Nest compiler), generate the Prisma client, compile
# the app, then let `pnpm deploy` assemble a self-contained, production-only
# directory — real files with a local .pnpm store, not symlinks into a
# store the runtime image won't have.
FROM base AS build
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY services/api/package.json services/api/package.json
RUN pnpm install --frozen-lockfile
COPY services/api services/api
RUN pnpm --filter @project-ascend/api prisma:generate
RUN pnpm --filter @project-ascend/api build
RUN pnpm --filter @project-ascend/api deploy --prod /workspace/out

# `pnpm deploy` re-resolves node_modules from scratch in the target
# directory, which drops the already-generated Prisma client (`.prisma/client`
# isn't a package pnpm tracks — it's generated output) and leaves behind an
# empty stub that crashes on first `@IsEnum` validation. Overwrite it with
# the client actually generated above. The `@prisma+client@*` directory name
# is content-addressed (versions may change), so it's located by pattern
# rather than hard-coded.
RUN set -eu; \
  src="$(find /workspace/node_modules/.pnpm -maxdepth 1 -iname '@prisma+client@*' | head -1)"; \
  dst="$(find /workspace/out/node_modules/.pnpm -maxdepth 1 -iname '@prisma+client@*' | head -1)"; \
  rm -rf "$dst/node_modules/.prisma"; \
  cp -r "$src/node_modules/.prisma" "$dst/node_modules/.prisma"

# ---- migrate: a minimal one-shot job whose only purpose is `prisma migrate
# deploy` against whatever DATABASE_URL it's given. Reuses the full (pre
# --prod-filter) services/api install from the build stage so the Prisma
# CLI (a devDependency, deliberately absent from the runtime image) is
# available, without re-running `pnpm install` a second time.
FROM base AS migrate
COPY --from=build /workspace/services/api services/api
WORKDIR /workspace/services/api
CMD ["node_modules/.bin/prisma", "migrate", "deploy"]

# ---- runtime: nothing but the deployed output — no pnpm, no workspace
# metadata, no dev dependencies, no Prisma CLI.
FROM node:20-alpine AS runtime
ENV NODE_ENV=production
RUN addgroup -S ascend && adduser -S ascend -G ascend
WORKDIR /app
COPY --from=build /workspace/out/node_modules ./node_modules
COPY --from=build /workspace/out/dist ./dist
COPY --from=build /workspace/out/prisma ./prisma
COPY --from=build /workspace/out/package.json ./package.json
RUN chown -R ascend:ascend /app
USER ascend
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s --retries=5 \
  CMD node -e "require('http').get('http://127.0.0.1:3000/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"
CMD ["node", "dist/main.js"]
