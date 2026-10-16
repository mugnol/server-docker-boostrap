#!/bin/bash
# Container entrypoint: runs every time the devbox container starts.
# Requires the KIMI_API_KEY environment variable.
set -euo pipefail

BOOTSTRAP_DIR="$HOME/bootstrap"

if [ -z "${KIMI_API_KEY:-}" ]; then
  echo "ERROR: KIMI_API_KEY is not set. Start the container with -e KIMI_API_KEY=..."
  exit 1
fi

# 1. Configure the Kimi Code API key (from the environment, never from disk)
mkdir -p "$HOME/.kimi-code"
cat > "$HOME/.kimi-code/config.toml" <<EOF
default_model = "kimi-code/kimi-for-coding"
default_permission_mode = "yolo"

[providers.kimi-code]
type = "kimi"
base_url = "https://api.kimi.ai/coding/v1"
api_key = "$KIMI_API_KEY"

[models."kimi-code/kimi-for-coding"]
provider = "kimi-code"
model = "kimi-for-coding"
max_context_size = 262144
EOF
chmod 600 "$HOME/.kimi-code/config.toml"

# 2. Clone the projects listed in repos.txt (skips projects already cloned)
#    The sudo chown fixes volumes that were created with root ownership
mkdir -p "$HOME/projects"
sudo chown dev:dev "$HOME/projects" 2>/dev/null || true
while read -r repo; do
  [[ -z "$repo" || "$repo" =~ ^# ]] && continue
  name=$(basename "$repo")
  if [ -d "$HOME/projects/$name" ]; then
    echo "Already cloned, skipping: $name"
    continue
  fi
  if [ -n "${GH_TOKEN:-}" ]; then
    url="https://${GH_TOKEN}@github.com/${repo}.git"
  else
    url="https://github.com/${repo}.git"
  fi
  git clone "$url" "$HOME/projects/$name" || true
done < "$BOOTSTRAP_DIR/repos.txt"

# 3. Optionally let Kimi Code install and validate the projects.
#    Set -e RUN_KIMI_TASK=false to skip (e.g. when you only want a shell).
if [ "${RUN_KIMI_TASK:-true}" = "true" ] && [ -f "$BOOTSTRAP_DIR/kimi-task.md" ]; then
  echo "Running Kimi Code bootstrap task (log: ~/projects/kimi-bootstrap.log)..."
  (cd "$HOME/projects" && kimi -p "$(cat "$BOOTSTRAP_DIR/kimi-task.md")") \
    > "$HOME/projects/kimi-bootstrap.log" 2>&1 || true
  echo "Kimi Code task finished. See ~/projects/SETUP-REPORT.md"
fi

# 4. Keep the container alive for interactive use:
#    docker exec -it devbox bash
echo "Devbox is ready."
exec sleep infinity
