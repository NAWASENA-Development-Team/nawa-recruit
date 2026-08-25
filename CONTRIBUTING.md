# Contributing to Nawa-Recruit

We appreciate your interest in contributing to Nawa-Recruit. As a core infrastructure platform for recruitment operations, we maintain high standards for code quality, performance, and architectural consistency.

This document outlines the process for contributing to the repository.

## Development Workflow

1. **Fork and Clone:** Fork the repository to your own GitHub account and clone it to your local machine.
2. **Branching Strategy:** Create a well-named branch from `main` for your work.
   - Feature: `feat/your-feature-name`
   - Bugfix: `fix/your-bugfix-name`
   - Refactor: `refactor/your-refactor-name`
3. **Local Setup:** Ensure you are using `bun` as the package manager to maintain deterministic builds.
   ```bash
   bun install
   ```
4. **Testing & Linting:** Ensure your code adheres to the project's formatting rules. Run the development server to verify UI/UX changes on both desktop and mobile viewports.

## Code Standards

- **Svelte 5 Runes:** We exclusively use the Svelte 5 Runes paradigm (`$state`, `$derived`, `$effect`) for reactivity. Do not introduce legacy Svelte 4 store patterns.
- **Tailwind CSS v4:** Utilize Tailwind utility classes for styling. Avoid writing custom CSS in `<style>` blocks unless absolutely necessary for complex animations or pseudo-elements.
- **Type Safety:** TypeScript is mandatory. Avoid the `any` type whenever possible, except in isolated integration boundaries (e.g., untyped Supabase SDK wrappers during MVP phases).
- **Mobile-First:** All UI components must prioritize touch ergonomics and display correctly on viewport widths down to 320px.

## Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/). This allows us to automate changelog generation.

Example:
- `feat(eval): add real-time websocket synchronization`
- `fix(auth): resolve RLS recursion loop`
- `docs(readme): update system architecture diagram`

## Pull Request Process

1. Ensure your PR description clearly describes the problem and the solution.
2. Link any relevant issue numbers in the PR description.
3. Update the `README.md` with details of changes to the interface, architecture, or new environment variables if applicable.
4. Your pull request will be reviewed by the maintainers. We may request changes to ensure architectural alignment.

## Getting Help

If you need architectural guidance or have questions regarding the codebase before starting your contribution, please reach out directly:

📧 **Contact:** [ferdi@nawasena.site](mailto:ferdi@nawasena.site)

By contributing, you agree that your contributions will be licensed under the project's primary license.
