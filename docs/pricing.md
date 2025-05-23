# LLM Pricing Comparison

## Claude Models (Anthropic)

### Claude Sonnet 4
- **Input**: $3 per million tokens
- **Output**: $15 per million tokens
- Available on: Anthropic API, Amazon Bedrock, Google Cloud Vertex AI
- Context window: 200K tokens (supports up to 64K output tokens)
- Prompt caching: Up to 90% cost savings
- Batch processing: 50% cost savings

### Claude 3.5 Haiku
- **Input**: $0.80 per million tokens  
- **Output**: $4 per million tokens
- Available on: Anthropic API, Amazon Bedrock, Google Cloud Vertex AI
- Amazon Bedrock latency-optimized version:
  - Input: $1 per million tokens
  - Output: $5 per million tokens (60% faster inference)
- Prompt caching: Up to 90% cost savings
- Message Batches API: 50% cost savings

## Google Gemini Models

### Gemini 2.5 Flash (Preview)
- **Input**: $0.15 per million tokens (text/image/video), $1.00 (audio)
- **Output**: 
  - Non-thinking: $0.60 per million tokens
  - Thinking: $3.50 per million tokens
- Context window: 1 million tokens
- Free tier available with rate limits
- Grounding with Google Search: 1,500 RPD free, then $35/1,000 requests

*Note: Google Gemini Flash 2.5 is currently in preview. Pricing and features may change before general availability.*

## Summary

**Most Cost-Effective for High Volume**: Claude 3.5 Haiku at $0.80/$4
**Balanced Performance/Price**: Gemini 2.5 Flash at $0.15/$0.60 (non-thinking)
**Premium Performance**: Claude Sonnet 4 at $3/$15

All models offer significant cost savings through caching and batch processing features. Gemini 2.5 Flash includes hybrid reasoning capabilities with separate pricing for thinking vs non-thinking tokens.