ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-alpine AS alpine

FROM alpine AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

FROM base AS builder
ARG PROJECT=web
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
RUN apk update
# Set working directory
WORKDIR /app
# RUN npm install -g pnpm
RUN pnpm add turbo --global
COPY . .
RUN turbo prune --scope=${PROJECT} --docker

# Add lockfile and package.json's of isolated subworkspace
FROM base AS installer
ARG PROJECT=web
RUN apk add --no-cache libc6-compat
RUN apk update
WORKDIR /app

# First install the dependencies (as they change less often)
COPY .gitignore .gitignore
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
RUN pnpm install

# Build the project
COPY --from=builder /app/out/full/ .
COPY turbo.json turbo.json

RUN pnpm turbo build --filter=${PROJECT}

FROM base AS runner
ARG PROJECT=web
WORKDIR /app

# Don't run production as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

COPY --from=installer /app/apps/${PROJECT}/next.config.js .
COPY --from=installer /app/apps/${PROJECT}/package.json .

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=installer --chown=nextjs:nodejs /app/apps/${PROJECT}/.next/standalone ./
COPY --from=installer --chown=nextjs:nodejs /app/apps/${PROJECT}/.next/static ./apps/${PROJECT}/.next/static
COPY --from=installer --chown=nextjs:nodejs /app/apps/${PROJECT}/public ./apps/${PROJECT}/public

WORKDIR /app/apps/${PROJECT}

ARG PORT=3010
ENV PORT=${PORT}
ENV NODE_ENV=production
EXPOSE ${PORT}

CMD ["node", "server.js"]
