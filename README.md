# Nawa-Recruit

> A high-throughput recruitment operations and evaluation platform.

Nawa-Recruit is a purpose-built system designed to orchestrate large-scale candidate selections. By decoupling administrative logistics from the evaluation experience, the platform enables organizations to process candidates with precision, speed, and real-time data synchronization.

## System Architecture

The platform is engineered around three core principles:

- **Zero-Latency Synchronization:** Utilizing Postgres-backed WebSockets, the evaluation queue updates instantly across all active evaluator sessions. This prevents grading collisions without requiring manual state refreshes.
- **Mobile-First Ergonomics:** Evaluators operate in the field. The interface is meticulously crafted for touch devices, prioritizing tactile feedback, context-aware layouts, and cognitive efficiency.
- **Frictionless Ingestion:** Administrative bottlenecks are minimized through native `.xlsx` (spreadsheet) and `.docx` (document) parsing pipelines, allowing bulk data onboarding in milliseconds.

## Key Capabilities

- **Concurrent Evaluation Engine:** Multiple evaluators can operate within the same room simultaneously. The relational schema ensures isolated scoring vectors that aggregate seamlessly into a unified metric.
- **CBT-Style Assessment Interface:** Evaluators are presented with a focused, distraction-free environment. Numeric inputs are instantly evaluated against a predefined, automated grading rubric (S/A/B/C/D).
- **Batch Allocation Pipeline:** Candidate routing is handled via a dual-pane bulk assignment interface, designed for rapid organizational scaling.
- **Live Leaderboard Aggregation:** Weighted scores are computed and ranked continuously, providing administrators with a real-time pulse of the recruitment cohort.

## Technical Foundation

Built for performance and maintainability:
- **Frontend:** Svelte 5 (leveraging the *Runes* paradigm for granular reactivity) & Tailwind CSS v4.
- **Backend Infrastructure:** Supabase (PostgreSQL, strict Row Level Security, Realtime Subscriptions).
- **Data Pipelines:** `xlsx` (SheetJS) for spreadsheet parsing, `mammoth` for robust document extraction.
- **Package Management:** Bun (optimized for speed and deterministic dependency resolution).

## Getting Started

### Prerequisites
- [Bun](https://bun.sh/) (v1.0+)
- A [Supabase](https://supabase.com/) project instance

### Local Environment Setup

1. **Repository Initialization**
   ```bash
   git clone https://github.com/NAWASENA-Development-Team/nawa-recruit
   cd nawa-recruit
   bun install
   ```

2. **Environment Configuration**
   Duplicate the environment template and populate it with your Supabase credentials.
   ```bash
   cp .env.example .env
   ```

3. **Database Provisioning**
   Execute the migration scripts located in `supabase/migrations/` via your Supabase SQL Editor in the following sequence:
   * `00001_initial_schema.sql` — Core schema and RLS policies
   * `00002_auth_trigger.sql` — Automated user provisioning
   * `00003_seed_data.sql` — Baseline data and criteria setup
   * `00004_enable_realtime.sql` — WebSocket publication configuration

4. **Launch Development Server**
   ```bash
   bun run dev
   ```

## Security & Access Control

Nawa-Recruit enforces strict Row Level Security (RLS) directly at the database layer. The platform is designed strictly for internal enterprise use; public registration is explicitly disabled. Operational accounts must be provisioned securely via the central authentication provider.
