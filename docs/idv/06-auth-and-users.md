# Authentication and users

This section explains how to create and manage users, configure sign-in methods, and control access through roles and permissions. 

## Create the first user

A new IDV installation has **no accounts and no default password.** Nobody can sign in until you
create the first user.

Run the following command once after installing IDV to create the first administrator account:

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

The `--name` value must be unique. After you create the first administrator account, add additional users through the portal or API. You do not need to run the `idv user create` command again unless you specifically want to create another user from the command line.

> The password is briefly visible inside the pod while the command runs. In stricter environments,
> use this account only to create the real ones, then delete it.

## Sign-in methods

| Method | Setting | Default |
|---|---|---|
| Username and password | `config.basicAuth.enabled` | On |
| OAuth 2.0 (Google, Microsoft, Cognito) | `config.oauth2.enabled` | Off |
| SAML | `config.saml.enabled` | Off |

`config.basicAuth.enabled` controls username and password sign-in. It is enabled by default, and the
first admin account you create relies on it.

> If you intend to use SSO exclusively, configure and test your provider before turning this off,
> and make the change in a test environment first. Username and password sign-in remains available as a backup if the SSO provider is misconfigured.

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

Permissions use the format `scope:operation`, where `scope` is the resource and `operation` defines what the user can do with it. For example, `session:read` allows the user to read their own sessions. 

Available operations are: 
- `read` - view data
- `write` - create or update data
-  `delete` - delete data
- `subscribe` - receive updates

A scope ending in `_all` covers everyone's records rather than
just the user's own. For example, `session:read_all`  allows the user to read sessions belonging to all users.

Create a custom role:

```bash
curl -X POST "https://idv.example.com/api/security/roles" \
  -H "Authorization: Token <token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Session Observer", "permissions": ["session:read", "session:subscribe"]}'
```

> **Note:** Changing someone's roles **replaces** their entire list of roles. Include all roles the user should keep when updating them:

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

Roles and permissions summarized from the
[Regula IDV user management documentation](https://docs.regulaforensics.com/develop/idv/administration/user-management/).
