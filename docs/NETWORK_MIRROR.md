# Terraform Provider Network Mirror

This repository publishes a Terraform provider network mirror for `terraform-provider-postgresql` on GitHub Pages.

## What is a Network Mirror?

A Terraform [network mirror](https://developer.hashicorp.com/terraform/internals/provider-network-mirror-protocol) is a static HTTP server that hosts Terraform provider packages. This allows organizations to:

- **Control provider distribution**: Host providers internally
- **Improve reliability**: Reduce dependency on external registries
- **Increase performance**: Faster downloads from a local/regional mirror
- **Support air-gapped environments**: Use Terraform without internet access

## Usage

### Configure Terraform CLI

Add the following to your Terraform CLI configuration file:

**Linux/macOS:** `~/.terraformrc`
**Windows:** `%APPDATA%\terraform.rc`

```hcl
provider_installation {
  network_mirror {
    url = "https://swile.github.io/terraform-provider-postgresql/"
    include = ["registry.terraform.io/cyrilgdn/postgresql"]
  }
}
```

### Use the Provider

In your Terraform configuration:

```hcl
terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.0"
    }
  }
}

provider "postgresql" {
}
```

### Verify Configuration

Run `terraform init` to verify that Terraform is using the network mirror:

```bash
terraform init
```

You should see output indicating the provider is being downloaded from the mirror URL.

## How It Works

1. **Release Creation**: When a new release is created (via the `release` workflow), GoReleaser builds provider binaries for multiple platforms
2. **Mirror Publication**: The `publish-mirror` job downloads release artifacts and generates the required metadata structure
3. **GitHub Pages Deployment**: Files are deployed to the `gh-pages` branch and served via GitHub Pages

## Mirror Structure

The network mirror follows the [Terraform provider network mirror protocol](https://developer.hashicorp.com/terraform/internals/provider-network-mirror-protocol):

```
registry.terraform.io/
└── cyrilgdn/
    └── postgresql/
        ├── index.json                    # Available versions
        └── {VERSION}.json                # Platform-specific downloads
        └── {VERSION}/
            ├── terraform-provider-postgresql_{VERSION}_{OS}_{ARCH}.zip
            └── terraform-provider-postgresql_{VERSION}_SHA256SUMS
```

## Supported Platforms

The following platforms are built and published:

- `darwin_amd64` (macOS Intel)
- `darwin_arm64` (macOS Apple Silicon)
- `linux_amd64` (Linux 64-bit)
- `linux_386` (Linux 32-bit)
- `linux_arm64` (Linux ARM 64-bit)
- `linux_arm` (Linux ARM)

## Development

### Testing the Mirror Locally

1. Build the provider:

   ```bash
   go build -o terraform-provider-postgresql
   ```

2. Generate mirror metadata:

   ```bash
   ./scripts/generate-mirror-metadata.sh <version> cyrilgdn postgresql ./mirror/registry.terraform.io
   ```

3. Serve the mirror locally:

   ```bash
   cd mirror
   python3 -m http.server 8080
   ```

4. Configure Terraform to use the local mirror:
   ```hcl
   provider_installation {
     network_mirror {
       url = "http://localhost:8080/registry.terraform.io/"
     }
   }
   ```

## Troubleshooting

### Provider Not Found

If Terraform cannot find the provider:

1. Verify the mirror URL is correct in your `~/.terraformrc`
2. Check that the version exists in the [versions metadata](https://swile.github.io/terraform-provider-postgresql/providers.tf.swile.co/cyrilgdn/postgresql/index.json)
3. Ensure your platform is supported

### Checksum Verification Failed

If checksums don't match:

1. Re-download the provider by removing the Terraform cache: `rm -rf ~/.terraform.d/plugins`
2. Run `terraform init` again
3. If the issue persists, check the release artifacts on GitHub

## References

- [Terraform Provider Network Mirror Protocol](https://developer.hashicorp.com/terraform/internals/provider-network-mirror-protocol)
- [Terraform CLI Configuration](https://developer.hashicorp.com/terraform/cli/config/config-file#provider-installation)
- [GoReleaser Documentation](https://goreleaser.com/)
