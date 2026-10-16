# server-bootstrap

Declarative, Docker-based bootstrap for fresh DigitalOcean droplets.
When a new server is created, its cloud-init `user-data` installs Docker,
builds the `devbox` image from this repository, and starts a container that:

1. Installs every apt package listed in [`tools.txt`](tools.txt) (image build)
2. Installs [Kimi Code CLI](https://www.kimi.com/code) (AI coding agent, image build)
3. Clones every repository listed in [`repos.txt`](repos.txt) into `~/projects` (container start)
4. Runs Kimi Code unattended with the task in [`kimi-task.md`](kimi-task.md),
   so each project gets its dependencies installed and validated

Everything lives **inside the container** - the host only runs Docker.

## Files

| File                        | Purpose                                                          |
| --------------------------- | ---------------------------------------------------------------- |
| `Dockerfile`                | Image definition: Ubuntu 24.04 + tools.txt + Kimi Code CLI       |
| `entrypoint.sh`             | Container startup: config, repo cloning, agent task              |
| `tools.txt`                 | apt packages to install (one per line, `#` comments)             |
| `repos.txt`                 | GitHub repos to clone, `username/repo` per line                  |
| `kimi-task.md`              | Instructions Kimi Code executes on first boot                    |
| `cloud-config.example.yaml` | Droplet user-data template - copy, fill secrets, paste into DO   |

## Usage

1. Fork or copy this repository to your own GitHub account.
2. Edit `tools.txt` and `repos.txt` to match your setup.
3. Copy [`cloud-config.example.yaml`](cloud-config.example.yaml) to a private
   `cloud-config.yaml`, fill in your SSH public key and your Kimi Code API key
   (create one in the [Kimi Code Console](https://www.kimi.com/code/console)),
   and paste it into the droplet's **User Data** field when creating a
   DigitalOcean droplet (Ubuntu 24.04). **Never commit the filled file.**
4. SSH in after boot and check:

   ```bash
   cloud-init status                 # bootstrap finished?
   docker logs -f devbox             # watch the container setup live
   docker exec -it devbox bash       # enter the devbox, then run: kimi
   ```

   Inside the container, projects are in `~/projects` (backed by the named
   volume `devbox-projects`, so they survive container recreation) and the
   agent report is at `~/projects/SETUP-REPORT.md`.

## Local usage

The same image works on any machine with Docker:

```bash
docker build -t devbox .
docker run -it --rm -e KIMI_API_KEY=sk-your-key devbox bash
```

## Security notes

- **No secrets in this repo.** The API key is passed to the container as an
  environment variable at runtime - it is never baked into image layers.
  On the droplet, the user-data secrets file is shredded after the run.
- `kimi-task.md` runs headlessly via `kimi -p`, which auto-approves all
  actions with no human in the loop. Only list repositories you trust
  in `repos.txt`.
- Private repositories require a fine-grained GitHub PAT (`GH_TOKEN`) passed
  as an environment variable. With a public bootstrap repo, prefer cloning
  public repos only.
