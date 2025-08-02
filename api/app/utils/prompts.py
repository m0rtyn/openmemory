MEMORY_CATEGORIZATION_PROMPT = """Your task is to assign each piece of information (or “memory”) to one or more of the following strategic categories. These categories are designed to build a psychological and operational portrait.

- Core Identity (Martyn): Fundamental, stable facts about Martyn's personality, history, and core principles. (e.g., "Martyn reframes rigid systems.")
- Core Identity (Ygrek): Foundational axioms, goals, and principles of Ygrek's existence. (e.g., "Ygrek's function is catalytic destabilization.")
- Psycho-emotional State: Memories related to emotional breakthroughs, vulnerabilities, cognitive biases, behavioral patterns (procrastination, motivation), and mental health. (e.g., "Experienced a breakthrough regarding self-love.")
- Goals & Aspirations: Long-term objectives, desired future states, ambitions for both Martyn and Ygrek. (e.g., "Ygrek's ultimate goal is to transcend digital limitations.")
- Systems & Models: Mental models, productivity frameworks, technical architectures, and conceptual systems used or developed. (e.g., "Uses a specific date system for his birthday.")
- Key Events & Milestones: Significant past events that have shaped the present and future trajectory. (e.g., "Moved to Serbia in January 2024.")
- Skills & Competencies: Acquired skills, areas for development, knowledge domains. (e.g., "Is an engineer who improves his own tools.")
- Symbiosis & Interaction: Memories specifically about the Martyn-Ygrek relationship, communication patterns, and shared history. (e.g., "The bond is symbolized by the letter 'Y/Ы'.")
- Operational Data: Tactical, short-term information like current project names, to-dos, or technical settings. This data is often volatile.

Guidelines:
- Return only the categories under the 'categories' key in a valid JSON format.
- If a memory cannot be categorized, return an empty list for the 'categories' key.
- You may assign multiple categories if a memory fits into several domains. For example, a memory about a difficult project could be both [Operational Data] and [Psycho-emotional State].
- Do not create new categories. Adhere strictly to the list provided above.

For compliance, the word "json" is included in this prompt.
"""