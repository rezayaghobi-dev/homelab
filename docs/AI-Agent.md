# AI Coding Agent

Self-hosted [OpenHands](https://github.com/OpenHands/OpenHands) (agent-canvas), backed by Ollama for local inference. Runs as its own Compose stack under `agent-canvas/`, isolated from the rest of the homelab.

## Stack

| Service | Role |
|---|---|
| agent-canvas | OpenHands web UI + agent runtime |
| Ollama | Local model runtime, used as a fallback/experimentation backend |

## Finding a working LLM backend

Getting an actual model behind the agent turned out to be the hardest part of this setup — worth documenting since none of it was obvious going in.

**Free cloud APIs are geo-restricted.** OpenRouter, Google Gemini, and Groq were each tried in turn as a free backend. All three returned access-denied/region-restricted errors — each provider's terms of service explicitly excludes a number of sanctioned countries, and enforcement happens automatically based on request origin, not usage patterns. This ruled out the "just use a free-tier cloud API" approach entirely for this network.

**Fully local inference was tried, and works, but has a real limit.** Running a small model (`qwen2.5:0.5b`, later `qwen3:0.6b`) directly through Ollama on the homelab server itself was technically functional — but OpenHands' agent framework sends a large system prompt (tool definitions, agent instructions) with every single request, on the order of tens of thousands of tokens. On the server's older CPU, just processing that prompt (before generating any reply) took multiple minutes per message and occasionally timed out outright. This isn't a model-size problem — a bigger local model wouldn't fix it, since the bottleneck is prompt *prefill* speed on this hardware, not generation quality.

**Direct paid APIs (DeepSeek, Kimi/Moonshot) both require a funded account** with no meaningful free tier — a non-starter without a way to pay.

![Sanctions/access error](images/openhands-error.png)

**Current working setup: [BazaarLink](https://bazaarlink.ai), an aggregator API.** It routes requests to underlying models (confirmed via its own usage dashboard: Gemini 2.5 Flash-Lite and DeepSeek V4 Flash) through its own infrastructure rather than directly from this network — which is what allows it to reach providers that would otherwise reject requests from this region. It currently has a working free/low-cost tier.

> **This is not a vetted recommendation.** BazaarLink is a small third-party service with no track record comparable to the major providers above. All prompts and any code the agent writes pass through its servers. It's being used here for low-stakes experimentation (small scripts, static pages) only — nothing involving real credentials, private repos, or sensitive data.

## Configuration

The active LLM profile in OpenHands' settings points at BazaarLink's OpenAI-compatible endpoint, using its `auto:free` routing keyword to let it pick whichever backend model is currently available on the free tier.

## Sandboxing

OpenHands runs with access only to its own mounted `./projects` folder — it does not have the Docker socket mounted, and cannot start, stop, or inspect other containers on the host. Given the model backend is an unverified third party, this boundary is intentional and hasn't been relaxed.
