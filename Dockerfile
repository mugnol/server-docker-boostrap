# server-bootstrap devbox image.
# Contains: all tools from tools.txt + Kimi Code CLI.
# Projects are cloned and configured at container START (see entrypoint.sh),
# so no secrets or repos are baked into the image.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Create the dev user with passwordless sudo
RUN useradd -m -s /bin/bash dev \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/*

# Install the tools listed in tools.txt.
# Note: docker.io is skipped here - it only makes sense on the host.
COPY tools.txt /tmp/tools.txt
RUN apt-get update \
    && grep -vE '^\s*(#|$)' /tmp/tools.txt | grep -v '^docker\.io$' | xargs apt-get install -y \
    && rm -rf /var/lib/apt/lists/* /tmp/tools.txt

# Install Kimi Code CLI as the dev user
USER dev
WORKDIR /home/dev
RUN curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash
ENV PATH="/home/dev/.kimi-code/bin:${PATH}"

# Runtime configuration (repos to clone, agent task, startup logic)
COPY --chown=dev:dev repos.txt kimi-task.md /home/dev/bootstrap/
COPY --chown=dev:dev entrypoint.sh /home/dev/entrypoint.sh
RUN chmod +x /home/dev/entrypoint.sh

ENTRYPOINT ["/home/dev/entrypoint.sh"]
