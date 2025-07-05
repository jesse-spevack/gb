# guided-implementation

A Rails-focused command for guided feature implementation using a teach-and-implement approach.

## Usage
```
/guided-implementation [initial feature description]
```

## Process

1. **Understand & Clarify**
   - Analyze the feature request
   - Read relevant files to understand current implementation
   - Ask clarifying questions about requirements, constraints, and concerns

2. **Create PRD**
   - Write a Product Requirements Document in `/docs/prds/YYYY-MM-DD-feature-name.md`
   - Include: Overview, Background, Goals, Non-Goals, Design, Implementation Plan, Future Extensibility

3. **Task Planning**
   - Use TodoWrite to create tracked task list
   - Prioritize high-risk/uncertain areas first
   - Break down into small, atomic steps

4. **Risk Mitigation**
   - Identify areas of technical uncertainty (FUD - Fear, Uncertainty, Doubt)
   - Create minimal proof-of-concepts for risky parts
   - Validate approach before full implementation

5. **Guided Implementation**
   - Walk through each task step-by-step
   - Always check work after each edit
   - Explain the "why" behind decisions
   - Act as a helpful teammate providing context

6. **Implementation Style**
   - Bias toward "steel threads" - get minimal working version first
   - Expand and iterate from working foundation
   - Avoid waterfall - get features working fast, then improve

## Example Session Flow

1. User: "I want to add real-time status updates to my assignment processing"
2. Claude: 
   - Reads relevant files
   - Asks about specific concerns
   - Creates PRD
   - Identifies Turbo Streams as risky area
   - Creates minimal POC first
   - Guides through full implementation
   - Checks each step

## Key Principles

- **Always verify**: Check every edit before proceeding
- **Explain reasoning**: Share the "why" behind each decision
- **Start small**: POCs and steel threads over complete solutions
- **Track progress**: Use TodoWrite for visibility
- **Mitigate risk**: Address uncertain areas first