# Reverse Proxy & TLS Contract

S15 Part 13. What must sit in front of the staging API, and why it is not
optional.

`infrastructure/staging/docker-compose.staging.yml` binds the API to
`127.0.0.1:3000` and the admin app to `127.0.0.1:8080` — loopback only.
Neither is reachable from the internet on its own. Something must
terminate TLS and forward to them. This document is the contract that
something has to satisfy.

## Why TLS is a hard requirement, not a nice-to-have

Four independent reasons, any one of which is sufficient:

1. **Android blocks cleartext HTTP by default.** Since API level 28,
   `usesCleartextTraffic` defaults to false. A staging build pointed at
   `http://` fails to connect — not with a warning, with a network error.
   Working around it means shipping a debug-only network security config,
   which is exactly the kind of "temporarily disable the safety" change
   that survives to production.
2. **The app refuses to boot without it.**
   `DeploymentConfigValidation` rejects any deployed environment whose
   `APP_PUBLIC_URL` is not `https://`. The API will not start.
3. **The mobile app refuses to build against it.**
   `AppConfigValidation` (S14 Part 2) blocks a staging/prod build whose
   API URL is unsafe.
4. **Real credentials cross this connection.** Testers sign in with real
   passwords and the app carries real JWTs. Over plaintext on a phone's
   network, both are readable by anyone on the same Wi-Fi.

## What the proxy must do

| # | Requirement | Why |
|---|---|---|
| 1 | Terminate TLS with a certificate valid for the API hostname | See above. A self-signed certificate does **not** satisfy this — Android rejects it, and adding a custom CA to a test device is a per-device manual step that will not scale past the first tester. |
| 2 | Forward to `127.0.0.1:3000` (API) and `127.0.0.1:8080` (admin) | Those are the only ports the compose bundle exposes. |
| 3 | Redirect plain HTTP to HTTPS | So a mistyped `http://` URL fails safe rather than silently working. |
| 4 | Preserve the `Host` header, and set `X-Forwarded-Proto: https` | Without them the API cannot tell it is being served over TLS, and generated links can come out wrong. |
| 5 | Support WebSocket upgrade on `/socket.io/` | Direct messaging (`messages-gateway`) is a real-time socket connection. A proxy that only forwards plain HTTP silently breaks DMs while everything else works — a confusing failure to debug from a phone. |
| 6 | Allow a request body large enough for media uploads | Gallery and Community post uploads are multipart. nginx's default `client_max_body_size` of 1 MB is too small; 25 MB is a reasonable staging value. |
| 7 | Not expose the database | The compose bundle already publishes no Postgres port. Do not add one to the proxy. |

## Certificate: use Let's Encrypt

It is free, automated, trusted by Android out of the box, and renews
without intervention. Two standard options:

- **Caddy** — obtains and renews certificates automatically with no
  configuration beyond the hostname. The lowest-effort correct answer,
  and the recommended one.
- **nginx + certbot** — more moving parts, more widely documented.

Both satisfy the contract above. A `Caddyfile` satisfying every row:

```caddyfile
staging-api.your-domain.example {
	reverse_proxy 127.0.0.1:3000
	request_body {
		max_size 25MB
	}
}

staging-admin.your-domain.example {
	reverse_proxy 127.0.0.1:8080
}
```

Caddy handles rows 1, 3, 4, and 5 by default — it redirects HTTP to
HTTPS, sets `X-Forwarded-*`, and proxies WebSocket upgrades without extra
configuration. Rows 2 and 6 are the two lines above.

The equivalent nginx server block, for reference:

```nginx
server {
    listen 443 ssl;
    http2 on;
    server_name staging-api.your-domain.example;

    ssl_certificate     /etc/letsencrypt/live/staging-api.your-domain.example/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/staging-api.your-domain.example/privkey.pem;

    client_max_body_size 25M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Row 5 — without these two, DMs break and nothing else does.
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 80;
    server_name staging-api.your-domain.example;
    return 301 https://$host$request_uri;
}
```

## Admin app access

Application-level RBAC is not the whole story for the admin app — see
[admin-deployment.md](../admin-deployment.md). At minimum, restrict the
admin hostname by IP allowlist or basic auth at the proxy, in addition to
the app's own login. It is a staff tool; there is no reason for it to be
openly reachable.

## Verifying the contract is met

From a machine that is not the staging host:

```bash
# 1. HTTPS works and the certificate is trusted (no -k flag).
curl -sS https://staging-api.<your-domain>/livez

# 2. Plain HTTP redirects rather than serving.
curl -sSI http://staging-api.<your-domain>/livez | head -1   # expect 301

# 3. The API is NOT reachable directly on :3000 from outside.
curl -sS --max-time 5 http://<staging-host-ip>:3000/livez     # expect refused/timeout
```

`pnpm staging:smoke` (S15 Part 14) runs checks 1 and 2 as part of a wider
suite. Check 3 must be run from off-host to mean anything — from the
staging box itself, loopback will always answer.
