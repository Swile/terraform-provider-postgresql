#!/bin/bash
set -euox pipefail

# This script generates Terraform network mirror metadata
# Based on: https://developer.hashicorp.com/terraform/internals/provider-network-mirror-protocol

VERSION="${1:?VERSION required}"
NAMESPACE="${2:-cyrilgdn}"
PROVIDER_TYPE="${3:-postgresql}"
MIRROR_BASE="${4:-mirror/registry.terraform.io}"

PROVIDER_DIR="${MIRROR_BASE}/${NAMESPACE}/${PROVIDER_TYPE}"
VERSION_DIR="${PROVIDER_DIR}/${VERSION}"

echo "Generating network mirror metadata for ${NAMESPACE}/${PROVIDER_TYPE} version ${VERSION}"

# Ensure directory exists
mkdir -p "${VERSION_DIR}"

# Array to store platforms
declare -a PLATFORMS=()

# Process each zip file to extract platform information
for zip_file in "${VERSION_DIR}"/*.zip; do
    if [[ -f "$zip_file" ]]; then
        filename=$(basename "$zip_file")

        # Extract OS and ARCH from filename
        # Expected format: terraform-provider-postgresql_VERSION_OS_ARCH.zip
        if [[ $filename =~ terraform-provider-${PROVIDER_TYPE}_(.+)_([^_]+)_([^_]+)\.zip ]]; then
            version="${BASH_REMATCH[1]}"
            os="${BASH_REMATCH[2]}"
            arch="${BASH_REMATCH[3]}"

            # Normalize architecture names for Terraform
            case "$arch" in
                "386") arch="386" ;;
                "amd64") arch="amd64" ;;
                "arm64") arch="arm64" ;;
                "arm") arch="arm" ;;
            esac

            # Normalize OS names for Terraform
            case "$os" in
                "darwin") os="darwin" ;;
                "linux") os="linux" ;;
                "windows") os="windows" ;;
            esac

            platform="${os}_${arch}"
            PLATFORMS+=("$platform")

            echo "  Found platform: ${platform}"
        fi
    fi
done

# Remove duplicates from platforms array
PLATFORMS=($(printf '%s\n' "${PLATFORMS[@]}" | sort -u))

# Generate or update versions index.json for the provider
INDEX_FILE="${PROVIDER_DIR}/index.json"

if [[ -f "$INDEX_FILE" ]]; then
    # File exists, read existing versions and add new one
    echo "  Updating existing index.json with version ${VERSION}"

    # Use jq for proper JSON manipulation
    jq --arg version "$VERSION" '.versions[$version] = {}' "$INDEX_FILE" > "${INDEX_FILE}.tmp"
    mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
else
    # File doesn't exist, create it from scratch
    echo "  Creating new index.json with version ${VERSION}"
    cat > "$INDEX_FILE" << EOF
{
  "versions": {
    "${VERSION}": {}
  }
}
EOF
fi

# Generate version-specific download metadata
# Create platforms array for JSON
platforms_json=""
for i in "${!PLATFORMS[@]}"; do
    platform="${PLATFORMS[$i]}"

    # Split platform into os and arch
    IFS='_' read -r os arch <<< "$platform"

    # Find corresponding files
    zip_file="${VERSION_DIR}/terraform-provider-${PROVIDER_TYPE}_${VERSION}_${os}_${arch}.zip"

    if [[ -f "$zip_file" ]]; then
        # Get SHA256 from checksum file if it exists
        checksum_file="${VERSION_DIR}/terraform-provider-${PROVIDER_TYPE}_${VERSION}_SHA256SUMS"
        sha256=""

        if [[ -f "$checksum_file" ]]; then
            zip_basename=$(basename "$zip_file")
            sha256=$(grep "$zip_basename" "$checksum_file" | awk '{print $1}')
        fi

        # If no checksum file, compute it
        if [[ -z "$sha256" ]]; then
            sha256=$(sha256sum "$zip_file" | awk '{print $1}')
        fi

        # Add comma if not first element
        if [[ $i -gt 0 ]]; then
            platforms_json+=","
        fi

        platforms_json+=$(cat << PLATFORM_EOF

    "${os}_${arch}": {
      "url": "https://swile.github.io/terraform-provider-postgresql/registry.terraform.io/${NAMESPACE}/${PROVIDER_TYPE}/${VERSION}/terraform-provider-${PROVIDER_TYPE}_${VERSION}_${os}_${arch}.zip",
      "shasum": "${sha256}"
    }
PLATFORM_EOF
)
    fi
done

# Create version metadata JSON
cat > "${PROVIDER_DIR}/${VERSION}.json" << EOF
{
  "archives": {${platforms_json}
  }
}
EOF

echo "Network mirror metadata generated successfully!"
echo "Provider directory: ${PROVIDER_DIR}"
echo "Platforms: ${PLATFORMS[*]}"

