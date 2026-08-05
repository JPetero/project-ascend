# syntax=docker/dockerfile:1
FROM node:20-alpine AS base
WORKDIR /workspace
RUN corepack enable

FROM base AS deps
COPY pnpm-workspace.yaml package.json ./
COPY services/api/package.json services/api/package.json
RUN pnpm install --filter @project-ascend/api... --frozen-lockfile=false

FROM deps AS build
COPY services/api services/api
RUN pnpm --filter @project-ascend/api prisma:generate
RUN pnpm --filter @project-ascend/api build

FROM base AS runtime
ENV NODE_ENV=production
COPY --from=build /workspace/services/api/node_modules services/api/node_modules
COPY --from=build /workspace/services/api/dist services/api/dist
COPY --from=build /workspace/services/api/prisma services/api/prisma
COPY --from=build /workspace/services/api/package.json services/api/package.json
WORKDIR /workspace/services/api
EXPOSE 3000
CMD ["sh", "-c", "node dist/main.js"]
