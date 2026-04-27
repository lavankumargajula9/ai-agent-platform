# AI Agent Platform

Production-grade AI Agent Platform with MCP Server, LangGraph Agent, and Data Pipeline for Healthcare Claims processing.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AI Agent Platform                     │
├──────────────┬──────────────────┬───────────────────────┤
│  MCP Server  │  LangGraph Agent │    Data Pipeline      │
│              │                  │                       │
│ • validate   │ • intake         │ • Bronze (raw)        │
│ • eligibility│ • eligibility    │ • Silver (validated)  │
│ • lookup_cpt │ • validation     │ • Gold (analytics)    │
│ • flag_anomaly│ • decision      │ • Quality checks      │
│ • appeal     │ • appeal         │ • Lineage tracking    │
├──────────────┴──────────────────┴───────────────────────┤
│              PostgreSQL + pgvector                      │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Clone and configure
git clone https://github.com/lavankumargajula9/ai-agent-platform.git
cd ai-agent-platform
cp .env.example .env
# Edit .env with your ANTHROPIC_API_KEY

# 2. Start PostgreSQL
docker-compose up -d

# 3. Install dependencies
pip install -e ".[dev]"

# 4. Run the MCP server
python -m mcp_server.server

# 5. Run evaluations
python -m evals.run_evals
```

## Tech Stack

- **Python 3.11+** with Pydantic v2 and type hints throughout
- **MCP SDK** for Model Context Protocol server
- **LangGraph** for agentic workflow orchestration
- **PostgreSQL 16** with pgvector for structured + vector storage
- **Airflow** for data pipeline orchestration
- **FastAPI** for REST API
- **Docker Compose** for local development
- **GitHub Actions** for CI/CD and automated eval runs

## Project Structure

```
ai-agent-platform/
├── mcp_server/          # Layer 1: MCP Server with 5 healthcare tools
├── langgraph_agent/     # Layer 2: Multi-step claims processing agent
├── evals/               # Evaluation suite (55+ test cases)
├── data_pipeline/       # Layer 3: Medallion architecture ETL
├── api/                 # FastAPI REST endpoints
├── database/            # Schema definitions
├── seed_data/           # Sample claims data
├── config/              # Application configuration
├── deploy/              # Docker and AWS deployment
└── .github/workflows/   # CI/CD pipelines
```

## Design Decisions

- **Why MCP?** Model Context Protocol is becoming the standard for agent-tool integration. Building a production MCP server demonstrates hands-on extensibility.
- **Why LangGraph?** Stateful, multi-step agent workflows with explicit control flow, memory, and guardrails — production-grade, not a toy chain.
- **Why Medallion Architecture?** Bronze → Silver → Gold is the industry standard for data quality at scale. Each layer adds validation, normalization, and governance.
- **Why Healthcare Claims?** X12 EDI (270/271, 278, 837) is a complex, regulated domain that demonstrates precision, compliance awareness, and real-world data handling.

## License

MIT
