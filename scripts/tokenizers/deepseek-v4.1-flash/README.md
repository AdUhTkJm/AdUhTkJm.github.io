# DeepSeek-V4.1-Flash tokenizer

Vendored so `scripts/tokenize.mjs` can count tokens offline and reproducibly.
The tokenizer is the one published for the official model:

- Model: <https://huggingface.co/deepseek-ai/DeepSeek-V4.1-Flash>
- Revision: `314113f8a7dadb388215396ba5fbee2c610a04d6`
- License: MIT (see the model repository)

Files and SHA-256 checksums:

```text
c90dfa01249db1be4245780a052ede752e1361c612ac6d08e2bdada7d599476b  tokenizer.json
6ac8c8dc065ed118161d02dd532749ae3f52c243deac27872134fae2f50d8547  tokenizer_config.json
```

Do not edit these files by hand. When the tokenizer is upgraded, replace both
files, update the revision and checksums here, and regenerate
`src/generated/token-counts.json` with `pnpm tokens`. Token counts are only
comparable across pages generated with the same tokenizer revision.
