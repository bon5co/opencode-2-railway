# OpenCode 2 (the open-source AI coding agent, v2 API + web server) wrapped for Railway.
#
# What upstream ships: ghcr.io/anomalyco/opencode is a bare Alpine image with the
# opencode binary, ripgrep and sh. It has no git, bash, curl or interpreters, so an
# agent session cannot clone, commit, run a script or fetch a URL. This wrapper adds
# the lean toolset a coding agent needs and a boot script that:
#   - keeps config, credentials, sessions and the workspace on the volume at /data
#   - refuses to start without a server credential (the API is the agent's shell)
#   - prints an agent-readable contract block to the deploy log on every boot
#
# Pinned by digest: ghcr.io/anomalyco/opencode:2.1.1
FROM ghcr.io/anomalyco/opencode@sha256:4e5f11cde373ba76d868e9ba95ad3071dfac39b44f93a447104c2e6e98ffc06d

RUN apk add --no-cache \
      bash git curl jq openssh-client-default ca-certificates tini \
      python3 py3-pip uv nodejs npm \
 && git config --system --add safe.directory '*' \
 && git config --system init.defaultBranch main

# Baked defaults (templateGenerate drops literal variable defaults, so nothing that
# is not a per-deploy secret is a template variable). A user-set variable still wins.
ENV OPENCODE_DISABLE_AUTOUPDATE=1 \
    GIT_AUTHOR_NAME="OpenCode" \
    GIT_AUTHOR_EMAIL="opencode@localhost" \
    GIT_COMMITTER_NAME="OpenCode" \
    GIT_COMMITTER_EMAIL="opencode@localhost" \
    SHELL=/bin/bash

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

# Upstream ENTRYPOINT is ["opencode"]; replace it, the script execs opencode itself.
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
