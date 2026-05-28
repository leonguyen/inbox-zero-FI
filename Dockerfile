FROM node:24-bookworm-slim AS base

RUN apt-get update && apt-get install -y \
    openssl \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable

WORKDIR /app

COPY . .

RUN pnpm install --frozen-lockfile

RUN pnpm turbo prune web --docker

FROM node:24-bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    openssl \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable

WORKDIR /app

COPY --from=base /app .

RUN pnpm install --frozen-lockfile

RUN cd apps/web && pnpm prisma generate

RUN pnpm build

FROM node:24-bookworm-slim AS runner

RUN apt-get update && apt-get install -y openssl \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder /app .

EXPOSE 3000

CMD sh -c "cd apps/web && pnpm prisma migrate deploy && pnpm start"