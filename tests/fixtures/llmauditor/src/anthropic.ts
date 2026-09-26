import Anthropic from "@anthropic-ai/sdk";

export const anthropic = new Anthropic({ timeout: 20_000, maxRetries: 2 });
