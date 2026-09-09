# Authentication and users

## There is no default login

A new IDV installation has **no accounts and no default password.** Nobody can sign in until you
create the first user.

Run this once, after installing:

```bash
printf 'New admin password: '; read -rs IDV_ADMIN_PW; echo

kubectl exec -n regula-idv deploy/idv-api -- \
  idv user create \
    --name admin \
    --password "$IDV_ADMIN_PW" \
    --email admin@example.com \
    --roles admin

unset IDV_ADMIN_PW
```

It confirms the new account:

```
User: admin
        User ID: 6a8d73f54e4d7a8bc485207f
        Email: admin@example.com
        Roles: ['admin']
        Active: True
```

The name must be unique. After this, add people through the portal or the API — you should not need
this command again.

> The password is briefly visible inside the pod while the command runs. In stricter environments,
> use this account only to create the real ones, then delete it.

## Ways to sign in

| Method | Setting | Default |
|---|---|---|
| Username and password | `config.basicAuth.enabled` | On |
| OAuth 2.0 (Google, Microsoft, Cognito) | `config.oauth2.enabled` | Off |
| SAML | `config.saml.enabled` | Off |

`config.basicAuth.enabled` controls username and password sign-in. It is on by default, and the
first admin account you create relies on it.

> If you intend to use SSO exclusively, configure and test your provider before turning this off,
> and make the change in a test environment first. Username and password sign-in is your fallback if
> the provider is misconfigured.

## OAuth 2.0

Get a client ID and secret from your provider first. `type` must be `google`, `microsoft`, or
`cognito`.

```yaml
config:
  oauth2:
    enabled: true
    accessTokenTtl: 600
    refreshTokenTtl: 604800
    providers:
      - name: azure
        type: microsoft
        clientId: "<app_id>"
        secret: ""                    # comes from the Secret below
        scope: "email openid profile User.Read"
        defaultRoles: ["verifier"]
        defaultGroups: []
        urls:
          jwk: "https://login.microsoftonline.com/<tenant_id>/discovery/v2.0/keys"
          authorize: "https://login.microsoftonline.com/<tenant_id>/oauth2/v2.0/authorize"
          token: "https://login.microsoftonline.com/<tenant_id>/oauth2/v2.0/token"
          refresh: "https://login.microsoftonline.com/<tenant_id>/oauth2/v2.0/token"
          revoke: "https://login.microsoftonline.com/<tenant_id>/oauth2/v2.0/revoke"

env:
  - name: IDV_CONFIG__OAUTH2__PROVIDERS__0__SECRET
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: oauthAzureSecret }
```

Leave `secret: ""` — anything written there is stored in plain text. Providers are numbered from
zero in the order listed above.

Two things to get right:

- `name` becomes part of the sign-in return address, so register the same value with your provider.
- `config.baseUrl` must be correct, or the return redirect fails.

`defaultRoles` and `defaultGroups` apply to people signing in for the first time. Missing groups are
created automatically.

## SAML

```yaml
config:
  saml:
    enabled: true
    providers:
      - name: okta
        entityId: "<idp_entity_id>"
        defaultRoles: ["verifier"]
        defaultGroups: []
        ssoService:
          url: "https://<tenant>.okta.com/app/<app>/sso/saml"
        security:
          x509cert: "<base64>"
          spPrivateKey: ""      # comes from the Secret below
          spPublicCert: ""

env:
  - name: IDV_CONFIG__SAML__PROVIDERS__0__SECURITY__SPPRIVATEKEY
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: samlSpPrivateKey }
  - name: IDV_CONFIG__SAML__PROVIDERS__0__SECURITY__SPPUBLICCERT
    valueFrom:
      secretKeyRef: { name: idv-secrets, key: samlSpPublicCert }
```

Certificates and keys are base64-encoded. The private key must come from a Secret.

## Roles

A role is a bundle of permissions. Four come ready to use:

| Role | Who it is for |
|---|---|
| `admin` | Full access to all data and settings |
| `verifier` | Can view and verify, but not administer |
| `device` | Used by devices connecting to the platform, not people |
| `demo` | Demonstrations only |

Permissions are written as `scope:operation`, for example `session:read`. The operations are `read`,
`write`, `delete`, and `subscribe`. A scope ending in `_all` covers everyone's records rather than
just the user's own.

Create a custom role:

```bash
curl -X POST "https://idv.example.com/api/security/roles" \
  -H "Authorization: Token <token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Session Observer", "permissions": ["session:read", "session:subscribe"]}'
```

Changing someone's roles **replaces** their whole list, so include the ones they should keep:

```bash
curl -X PATCH "https://idv.example.com/api/security/users/<user_id>" \
  -H "Authorization: Token <token>" \
  -H "Content-Type: application/json" \
  -d '{"roles": ["verifier", "device"]}'
```

Access to individual workflows, views, and profile groups can be narrowed per person or group in the
portal, under **Settings**. The complete permission list is in the
[platform user management documentation](https://docs.regulaforensics.com/develop/idv/administration/user-management/).

## Next

- [Operations](07-operations.md)
- [Troubleshooting](08-troubleshooting.md)

---

Roles and permissions summarised from the
[Regula IDV user management documentation](https://docs.regulaforensics.com/develop/idv/administration/user-management/).
