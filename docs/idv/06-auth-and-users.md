# Authentication and Users

This section explains how to create and manage users, configure sign-in methods, and control access through roles and permissions. 

## Create the First User

A new IDV installation has **no accounts and no default password.** Nobody can sign in until you
create the first user.

Run the following command once after installing IDV to create the first administrator account:

```bash
printf 'New admin password: '; read -rs IDV_ADMIN_PW; echo

kubectl exec -n regula-idv deploy/idv-backoffice -- \
  idv user create \
    --name admin \
    --password "$IDV_ADMIN_PW" \
    --email admin@example.com \
    --roles admin

unset IDV_ADMIN_PW
```

The command returns the new account details:

```
User: admin
        User ID: 6a8d73f54e4d7a8bc485207f
        Email: admin@example.com
        Roles: ['admin']
        Active: True
```

The `--name` value must be unique. After you create the first administrator account, add additional users through the portal or API. You do not need to run the `idv user create` command again unless you specifically want to create another user from the command line.

> **Warning**
>
> The password is briefly visible inside the pod while the command runs. In environments with stricter security requirements, use this account only to create the required administrator accounts, then delete it.

## Sign-In Methods

| Method | Setting | Default |
|---|---|---|
| Username and password | `config.basicAuth.enabled` | true |
| OAuth 2.0 (Google, Microsoft, Cognito) | `config.oauth2.enabled` | false |
| SAML | `config.saml.enabled` | false |


### `config.basicAuth.enabled`

`config.basicAuth.enabled` controls the username and password sign-in method.

`config.basicAuth.enabled: true`: this is the default setting which enables username and password sign-in. The first administrator account created with `idv user create` uses this sign-in method. 

If SSO is also configured, users can sign in through SSO or with username and password. The local username/password login remains available as a backup if the SSO provider is misconfigured or temporarily unavailable.

`config.basicAuth.enabled: false`: disables the username and password sign-in completely, including for users created with `idv user create`. SSO remains the only available sign-in method.

If you want to use SSO exclusively, configure and verify SSO **before disabling Basic Auth**:

1. Create the local administrator with `idv user create`.
2. Configure SSO.
3. Verify that SSO login works.
4. Set `config.basicAuth.enabled: false`.

> **Important**
>
> If `config.basicAuth.enabled` is set to `false` before SSO is ready, or if SSO stops working, there is no alternative sign-in method. To restore access, set `config.basicAuth.enabled: true` and run `helm upgrade`.

### OAuth 2.0

Obtain a client ID and client secret from your OAuth 2.0 provider. `type` must be `google`, `microsoft`, or
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

Make sure the following settings are correct:

- `name` becomes part of the sign-in return address. Register the same value with your provider.
- `config.baseUrl` must contain the correct public URL. Otherwise, the return redirect fails.

`defaultRoles` and `defaultGroups` apply to people signing in for the first time. Missing groups are
created automatically.

### SAML

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

A role is a set of permissions. IDV provides four predefined roles:

| Role | Intended use |
|---|---|
| `admin` | Full access to all data and settings |
| `verifier` | Can view and verify, but not administer |
| `device` | Used by devices connecting to the platform, not people |
| `demo` | Demonstrations only |

Permissions use the format `scope:operation`, where `scope` is the resource and `operation` defines what the user can do with it. For example, `session:read` allows the user to read their own sessions. 

Available operations are:

- `read` — view data
- `write` — create or update data
- `delete` — delete data
- `subscribe` — receive updates

A scope ending in `_all` grants access to records belonging to all users rather than only the current user's records. For example, `session:read_all`  allows the user to read sessions belonging to all users.

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
