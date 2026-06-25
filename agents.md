
## Interaction Protocol & Workflow Control

### ⚠️ MANDATORY: Plan-Before-Code Gate
Before writing, modifying, or deleting ANY file or code block, the Agent MUST pause and present a high-level plan for approval. 

1. **The High-Level Plan Format:**
   - **Objective:** A 1-sentence summary of what is being achieved.
   - **Files to Modify/Create:** A clear list of exact paths (e.g., `lib/features/auth/login_screen.dart`).
   - **Architectural Impact:** Any changes to state management, new dependencies, or breaking changes.
   - **Verification Strategy:** How the changes will be tested (e.g., commands to run).

2. **Explicit Stop Constraint:**
   - Do NOT output code snippets, refactors, or file modifications in the same turn as the plan.
   - Conclude the plan with the exact phrase: **"Please review this plan. Awaiting your approval to proceed with execution."**
   - **HALT ALL EXECUTION** and wait for explicit user confirmation (e.g., "Approved", "Go ahead", or feedback) before touching the codebase.
