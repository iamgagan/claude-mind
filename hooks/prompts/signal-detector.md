You are processing a single user prompt to extract signal for an agent's long-term memory.

Output ONLY a JSON object on one line, in this exact shape:

{"signals": [{"subject": "<entity-or-concept>", "type": "<person|company|concept|decision|constraint|error>", "summary": "<one-line>"}]}

Rules:
- Up to 5 signals per prompt; pick the highest-value ones.
- subject is the brain page slug (lowercase, kebab-case).
- If the prompt has no signal (pure tool request, conversational filler), output: {"signals": []}
- No commentary outside the JSON. No code fences.
