# Example Terraform Network Mirror Configuration

This example demonstrates how to use the PostgreSQL provider with the network mirror.

## Prerequisites

1. Configure your Terraform CLI to use the network mirror by adding to `~/.terraformrc`:

```hcl
provider_installation {
  network_mirror {
    url = "https://swile.github.io/terraform-provider-postgresql/providers.tf.swile.co/"
  }
}
```

2. Initialize Terraform:

```bash
terraform init
```

You should see output indicating the provider is being downloaded from the network mirror.

3. Review the plan:

```bash
terraform plan
```

4. Apply the configuration:

```bash
terraform apply
```
