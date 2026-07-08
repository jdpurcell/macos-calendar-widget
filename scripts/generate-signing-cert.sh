#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Generates a self-signed code-signing certificate used to sign Calendar Widget
# in CI (see .github/workflows/release.yml).
#
# IMPORTANT: a self-signed signature is NOT trusted by macOS Gatekeeper. People
# who download the DMG still get an "unidentified developer" warning and must
# allow it once (System Settings -> Privacy & Security -> Open Anyway). This only
# gives the app a *stable, tamper-evident* signature; it is not notarization.
#
# Usage:  ./scripts/generate-signing-cert.sh [output-dir]
#         (default output dir: .signing/, which is git-ignored)
# ---------------------------------------------------------------------------

out_dir="${1:-.signing}"
cn="Calendar Widget Self-Signed"

mkdir -p "$out_dir"

key_pem="$out_dir/signing.key.pem"
cert_pem="$out_dir/signing.cert.pem"
p12_path="$out_dir/signing.p12"
b64_path="$out_dir/signing.p12.base64"
p12_pw_file="$out_dir/p12-password.txt"
kc_pw_file="$out_dir/keychain-password.txt"

# Random passwords. You paste these into the GitHub secrets.
p12_password="$(openssl rand -base64 18 | tr -d '\n')"
keychain_password="$(openssl rand -base64 18 | tr -d '\n')"

# X.509 config with the codeSigning extended key usage. Using a config file
# (rather than -addext) keeps this portable across LibreSSL and OpenSSL.
cfg="$(mktemp)"
trap 'rm -f "$cfg"' EXIT
cat > "$cfg" <<CFG
[req]
distinguished_name = dn
x509_extensions    = v3
prompt             = no
[dn]
CN = ${cn}
O  = Calendar Widget
[v3]
basicConstraints     = critical,CA:false
keyUsage             = critical,digitalSignature
extendedKeyUsage     = critical,codeSigning
CFG

# 1. Private key + self-signed certificate.
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$key_pem" -out "$cert_pem" -days 3650 -config "$cfg"

# 2. Bundle into a PKCS#12. OpenSSL 3 defaults to ciphers older `security
#    import` can't read, so pass -legacy there; LibreSSL already writes legacy.
if openssl version | grep -q '^OpenSSL 3'; then
  openssl pkcs12 -export -legacy -inkey "$key_pem" -in "$cert_pem" \
    -name "$cn" -passout "pass:${p12_password}" -out "$p12_path"
else
  openssl pkcs12 -export -inkey "$key_pem" -in "$cert_pem" \
    -name "$cn" -passout "pass:${p12_password}" -out "$p12_path"
fi

# 3. Base64 (single line) for the GitHub secret; save passwords alongside.
base64 < "$p12_path" | tr -d '\n' > "$b64_path"
printf '%s' "$p12_password"      > "$p12_pw_file"
printf '%s' "$keychain_password" > "$kc_pw_file"
chmod 600 "$key_pem" "$p12_path" "$b64_path" "$p12_pw_file" "$kc_pw_file"

cat <<EOF

✅ Self-signed code-signing certificate written to: $out_dir/

Add these three repository secrets on GitHub
  Settings -> Secrets and variables -> Actions -> New repository secret

  MACOS_CERT_P12_BASE64     copy with:  base64 < "$p12_path" | pbcopy
  MACOS_CERT_PASSWORD       copy with:  cat "$p12_pw_file" | pbcopy
  MACOS_KEYCHAIN_PASSWORD   copy with:  cat "$kc_pw_file" | pbcopy

Signing identity CN: $cn  (the workflow finds it automatically after import)

⚠️  $out_dir/ is git-ignored — never commit these files.
    Self-signed = users still allow the app once under Privacy & Security.
EOF
