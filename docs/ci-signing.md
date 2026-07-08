# Code signing in CI (self-signed)

The [release workflow](../.github/workflows/release.yml) signs `CalendarWidget.app`
and the DMG with a **self-signed** code-signing certificate before publishing.

> ⚠️ **Self-signed is not notarized.** macOS Gatekeeper does not trust a
> self-signed certificate, so anyone downloading the DMG still bypasses Gatekeeper
> on first launch (System Settings → Privacy & Security → *Open Anyway*, or
> `xattr -dr com.apple.quarantine /Applications/CalendarWidget.app`). Signing here
> gives the app a **stable, tamper-evident** signature — not notarization-grade
> trust. Warning-free installs require a paid Apple *Developer ID* certificate plus
> notarization.
>
> The workflow is **gated**: if the secrets below are absent it still builds and
> releases an ad-hoc (unsigned) DMG, so releases never break for lack of a cert.

## One-time setup

1. Generate the certificate locally:

   ```sh
   ./scripts/generate-signing-cert.sh
   ```

   This writes the key, certificate, a PKCS#12 bundle, its base64 encoding, and
   two random passwords into `.signing/` (git-ignored).

2. Add three **repository secrets** on GitHub
   (*Settings → Secrets and variables → Actions → New repository secret*):

   | Secret | How to copy its value |
   | --- | --- |
   | `MACOS_CERT_P12_BASE64` | `base64 < .signing/signing.p12 \| pbcopy` |
   | `MACOS_CERT_PASSWORD` | `cat .signing/p12-password.txt \| pbcopy` |
   | `MACOS_KEYCHAIN_PASSWORD` | `cat .signing/keychain-password.txt \| pbcopy` |

The next push to `main` produces a signed DMG. The workflow discovers the signing
identity automatically from the imported certificate, so there is no identity name
to configure.

## How it works

1. **Import** — decodes the p12 secret, creates a throwaway keychain on the runner,
   imports the certificate, and authorizes `codesign` to use it.
2. **Sign app** — signs the embedded widget extension first, then the app,
   re-applying each target's sandbox entitlements.
3. **Sign DMG** — signs the packaged disk image.
4. **Clean up** — deletes the temporary keychain.

To rotate the certificate, re-run the script and update the three secrets.
