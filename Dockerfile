FROM ubuntu:24.04

ARG GITCONFIG
ARG TZ=America/Denver

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=${TZ}

# Use interactive bash for all RUN so .bashrc is sourced and PATH (nvm, pnpm, bun) is set.
SHELL ["/bin/bash", "-i", "-c"]

# Install base dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    aggregate \
    build-essential \
    ca-certificates \
    curl \
    dnsutils \
    fzf \
    gh \
    git \
    gnupg2 \
    iproute2 \
    ipset \
    iptables \
    jq \
    less \
    man-db \
    pip \
    procps \
    python3 \
    python3-venv \
    ripgrep \
    sudo \
    unzip \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Create ai user and group with uid/gid 10000
RUN groupadd -g 10000 ai && \
    useradd -u 10000 -g 10000 -md /home/ai -s /bin/bash ai && \
    usermod -aG sudo ai && \
    sed -i 's|^ai:[^:]*:|ai:$y$j9T$zBOEQebG0rUTnLYW/l1WC/$.uCxX/KfgbU6d8qp/cRVGGWdravYJc9tVhrU5c7ybZ9:|' /etc/shadow

RUN mkdir -p /home/ai/.ssh /workspace && chmod 700 /home/ai/.ssh

# Create directories for each cli setup
# Add any other cli you would like that is missing
RUN mkdir -p  /home/ai/.claude
RUN mkdir -p  /home/ai/.codex
RUN mkdir -p  /home/ai/.cursor/rules
RUN mkdir -p  /home/ai/.gemini
RUN mkdir -p  /home/ai/.ai/


# Setup up aliases
RUN echo 'alias agent="agent --yolo"' >> /home/ai/.bashrc
RUN echo 'alias claude="claude --dangerously-skip-permissions"' >> /home/ai/.bashrc
RUN echo 'alias codex="codex --dangerously-bypass-approvals-and-sandbox"' >> /home/ai/.bashrc
RUN echo 'alias gemini="gemini --yolo"' >> /home/ai/.bashrc

# Copy and set up firewall script
# TODO: figure out a way to use this but not completely hamper the ai
#COPY init-firewall.sh /usr/local/sbin/
#RUN chmod +x /usr/local/sbin/init-firewall.sh && \
#  echo "ai ALL=(root) NOPASSWD: /usr/local/sbin/init-firewall.sh" > /etc/sudoers.d/ai-firewall && \
#  chmod 0440 /etc/sudoers.d/ai-firewall

# Copy default configs to image (won't be shadowed by volumes)
COPY configs/ /etc/ai/configs/
RUN chown -R ai:ai /etc/ai/configs

# Install global memory system
COPY shared/ /etc/ai/shared/

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod ugo+x /usr/local/bin/docker-entrypoint.sh

RUN chown -R ai:ai /workspace && chown -R ai:ai /home/ai

# Set timezone from build arg (e.g. America/New_York); leave as UTC if TZ=UTC or unset
RUN if [ -n "$TZ" ] && [ "$TZ" != "UTC" ]; then \
      ln -sf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" > /etc/timezone; \
    fi

USER ai
WORKDIR /home/ai

# Set up NVM environment
ENV NVM_DIR=/home/ai/.nvm
ENV NODE_VERSION=24
ENV HOME=/home/ai
ENV SHELL=bash
# Set the default editor and visual
ENV EDITOR=vim
ENV VISUAL=vim

# create venv for ai user
RUN python3 -m venv "$HOME/venv"

# Ensure subsequent RUN/CMD use venv Python and tools first.
ENV PATH="$HOME/venv/bin:$PATH"

# Install semgrep for targeted way to find bugs/security issues
RUN "$HOME/venv/bin/python" -m pip install --upgrade pip && \
    "$HOME/venv/bin/python" -m pip install semgrep

# Install nvm (latest release; pin to a version tag in the URL for reproducible builds)
RUN NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .tag_name) && \
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# Install Node.js 24 via nvm and set as default (.bashrc already has nvm from install script)
RUN nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default

# Ensure node and npm are available in non-interactive shells
ENV PATH="$NVM_DIR/versions/node/v$NODE_VERSION.*/bin:$PATH"

# Install pnpm and bun (as ai user so they install to user home directory)
RUN npm install -g pnpm && pnpm setup
# pnpm setup adds PATH to .bashrc; set it here too so pnpm is on PATH in later RUN and at runtime
ENV PNPM_HOME="/home/ai/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN curl -fsSL https://bun.sh/install | bash

# Install sqlite, needed for qmd
RUN pnpm add -g sqlite

# Don't add bun to ENV PATH here; the bun installer already adds it to .bashrc (would duplicate at runtime).
# Install qmd (github:tobi/qmd); if DependencyLoop, retry with Resolution spec then trust node-llama-cpp
RUN bun install -g github:tobi/qmd 2>&1 | tee /tmp/bun.out; \
  _e=${PIPESTATUS[0]}; \
  if [ $_e -ne 0 ] && grep -q DependencyLoop /tmp/bun.out; then \
    _spec=$(grep 'Resolution:' /tmp/bun.out | sed -n 's/.*Resolution: *"\([^"]*\)".*/\1/p' | head -1); \
    [ -n "$_spec" ] && bun install -g "$_spec" && _e=0; \
  fi; \
  bun pm -g trust node-llama-cpp; \
  exit $_e

# Install claude-code
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/ai/.bashrc

# Add memory plugin to PATH
RUN echo 'export PATH="/home/ai/.ai/plugins/memory/bin:$PATH"' >> /home/ai/.bashrc

# Install codex CLI
RUN npm install -g @openai/codex

# Install Gemini CLI
RUN npm install -g @google/gemini-cli

#Install cursor cli
RUN curl https://cursor.com/install -fsS | bash

RUN if [ -n "$GITCONFIG" ]; then \
      echo "$GITCONFIG" | base64 -d > /home/ai/.gitconfig; \
    fi

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
