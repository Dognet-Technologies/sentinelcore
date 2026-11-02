# Security

To report a vulnerability, email `security@dognet.tech`. Please don't open a public issue.

## Advisories

### SC-2026-001

**JWT signing key shared across installations**

| | |
|---|---|
| **Severity** | High |
| **Affected** | Packaged installs (tarball, OVA, qcow2) up to and including 2.0.0 |
| **Fixed in** | 2.0.1 |
| **Impact** | An authenticated user could raise their own privileges to administrator |

The installer wrote the per-instance JWT secret under a configuration key the
application does not read. Affected installs therefore used the default secret
shipped in this public repository. Session validation also trusted the role stored
in the token. The same key protected the plugin credentials stored in the database.

Unauthenticated access was not observed, because every request also needs an active
server-side session.

**What 2.0.1 changes**

- Each installation gets its own secret, and production refuses to start on a public default.
- The session must belong to the token's user, and the role is always read from the database.

**What to do after updating**

1. Run `upgrade.sh`. It generates a new secret, so all users have to sign in again.
2. Review administrator accounts and recent audit logs for unexpected changes.
3. Change the SMTP and OpenVAS passwords and save them again: the previous key is
   public, so values stored with it must be treated as exposed.

Default credentials set at first login, such as the initial appliance password, are
intentional and must be changed when the application asks for it.
