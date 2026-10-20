# opencode-2-railway

[OpenCode](https://opencode.ai) 2.x (the open-source AI coding agent, v2 API and web
server) wrapped for [Railway](https://railway.com).

The upstream image, `ghcr.io/anomalyco/opencode`, is a bare Alpine image with the
binary and ripgrep. It has no git, bash or curl, so an agent cannot clone a repo or
run a script. This wrapper adds a lean toolset (bash, git, curl, jq, ssh, ripgrep,
python3, pip, uv, node, npm) and a boot script that:

- refuses to start without `OPENCODE_SERVER_PASSWORD`
- keeps `HOME` (sessions, provider credentials, config) and the workspace on the
  volume at `/data`
- honours Railway's injected `$PORT` and listens dual-stack (`::`)
- prints an agent contract block to the log on every boot

Image: `ghcr.io/bon5co/opencode-2-railway:2.1.1`, built from
`ghcr.io/anomalyco/opencode:2.1.1` pinned by digest. See [AGENTS.md](AGENTS.md) for the
API contract and a working snippet.

```bash
docker run -d -p 8080:8080 -e PORT=8080 -e OPENCODE_SERVER_PASSWORD=change-me \
  -v "$PWD/data:/data" ghcr.io/bon5co/opencode-2-railway:2.1.1
```
