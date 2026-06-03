# Minimal cage image: just Node + the Copilot CLI.
# Deliberately NO git, NO ssh, NO credentials — the agent can edit, but never push.
FROM node:22-slim
RUN npm install -g @github/copilot@1.0.57
WORKDIR /work
