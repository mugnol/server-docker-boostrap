# Bootstrap task for Kimi Code

You are running unattended on a freshly provisioned Ubuntu server.
The directory `~/projects` contains repositories cloned from GitHub.

For EACH project in `~/projects`:

1. Read the README (and any package.json / requirements.txt / go.mod / Cargo.toml)
   to identify the stack.
2. Install its dependencies:
   - Node.js: `npm install` (or the package manager the repo uses)
   - Python: create a `.venv` and `pip install -r requirements.txt`
   - Other stacks: follow the README instructions
3. If a `.env.example` exists, copy it to `.env` (do NOT invent secret values).
4. Run the project's tests or build to validate the installation.
   If a step fails, try to fix it once; if it still fails, note it and move on.

Rules:
- Do NOT commit or push anything to git.
- Do NOT install anything globally with sudo.
- Do NOT modify system configuration.

When finished, write a summary report to `~/projects/SETUP-REPORT.md` listing,
for each project: what was installed, whether validation passed, and any
issues that need manual attention.
