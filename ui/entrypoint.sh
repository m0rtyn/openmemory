#!/bin/sh
set -e

# Ensure the working directory is correct
cd /app



# Replace placeholder tokens (__NEXT_PUBLIC_...__) with actual env values
for var in $(printenv | grep '^NEXT_PUBLIC_' | cut -d '=' -f1); do
  value=$(printenv $var | sed 's|/|\\/|g')
  token="__${var}__"
  echo "Injecting $var into build (token $token)"
  # Only replace if token present (silent otherwise)
  grep -R --null -l "$token" .next 2>/dev/null | while IFS= read -r -d '' file; do
    sed -i "s|$token|$value|g" "$file"
  done || true
done
echo "Runtime public env injection complete"


# Execute the container's main process (CMD in Dockerfile)
exec "$@"