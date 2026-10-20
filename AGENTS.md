# OpenCode 2 on Railway: agent guide

You deployed (or were handed) an OpenCode 2 server: the open-source AI coding agent
with its v2 HTTP API and web UI. Use it to run coding sessions remotely.

## Contract

| Item | Value |
| --- | --- |
| Public URL | `https://$RAILWAY_PUBLIC_DOMAIN` (template variable `OPENCODE_URL`) |
| Private URL | `http://<service>.railway.internal:<PORT>` (`PORT` is 8080 on Railway) |
| Auth | HTTP Basic. Username is always `opencode` (v2 ignores `OPENCODE_SERVER_USERNAME`). Password is the variable `OPENCODE_SERVER_PASSWORD`. |
| Health | `GET /` returns 200 with no credentials (static web UI shell). Every `/api/*` route and `/openapi.json` return 401 without credentials. |
| OpenAPI | `GET /openapi.json` (needs credentials) |
| State volume | `/data` (sessions, provider credentials, config under `/data/home`; default workspace `/data/workspace`) |

## Free model, no provider key

Provider `opencode`, model `big-pickle` answers without any API key. Add your own
provider key when you want a different model:

```bash
curl -s -u "opencode:$OPENCODE_SERVER_PASSWORD" -X POST \
  "$OPENCODE_URL/api/integration/anthropic/connect/key" \
  -H 'content-type: application/json' -d '{"key":"sk-..."}'
```

## Run a prompt

```bash
AUTH="opencode:$OPENCODE_SERVER_PASSWORD"
SID=$(curl -s -u "$AUTH" -X POST "$OPENCODE_URL/api/session" \
  -H 'content-type: application/json' -d '{}' | jq -r .data.id)
curl -s -u "$AUTH" -X POST "$OPENCODE_URL/api/session/$SID/prompt" \
  -H 'content-type: application/json' -d '{"text":"List the files in the workspace."}'
# the prompt call returns at once; poll the messages (newest first)
curl -s -u "$AUTH" "$OPENCODE_URL/api/session/$SID/message" | jq '.data[0]'
```

## Notes

- The default `build` agent already allows all tools. The only prompts for approval
  are reads of `.env` files; answer them at
  `POST /api/session/{id}/permission/{requestID}/reply`.
- `GET /api/credential` returns stored provider keys in clear text to an authenticated
  client. Treat the server password as the root secret.
- `GET /auth/connect/{code}` redeems a single-use pairing code without credentials.
  Codes are created by `POST /api/pair`, which needs the password.
- The server refuses to start when `OPENCODE_SERVER_PASSWORD` is empty.
- Tools in the image: bash, git, curl, jq, ssh, ripgrep, python3, pip, uv, node, npm.
