# Contributing to Project Ascend

Thanks for helping build Project Ascend. This repository is a modular-monolith monorepo containing a NestJS API and a Flutter mobile app.

> **Before implementing product behavior**, read the Project Ascend product documents in
> [`packages/docs/product/`](packages/docs/product/) (start with `founder-vision-bible.md`). They
> override unstated implementation assumptions but do not override security, law, platform policy,
> or verified technical constraints.

## Workflow

1. Create a feature branch from `main`.
2. Keep changes scoped — one module or feature per PR where practical.
3. Run the relevant lint/test suite before opening a PR (see root `README.md`).
4. Write descriptive commit messages in the imperative mood (e.g. "Add refresh token rotation").
5. Do not commit secrets, `.env` files, or generated Prisma clients.

## Code style

- Backend: TypeScript, ESLint + Prettier. No direct Prisma access from controllers — always go through a service.
- Mobile: Dart, `flutter analyze` must be clean. No business logic inside widgets — keep it in providers/notifiers/services.
- Prefer small, well-named functions over large ones. Comment only when the *why* isn't obvious from the code.

## Commit checklist

- [ ] `pnpm api:lint` passes
- [ ] `pnpm api:test` passes
- [ ] `flutter analyze` passes (from `apps/mobile`)
- [ ] `flutter test` passes (from `apps/mobile`)
- [ ] No secrets or `.env` files staged
