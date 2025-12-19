# Example Terraform configuration using the network mirror

terraform {
  required_version = ">= 1.0"

  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.14-swile.1"
    }
  }
}

provider "postgresql" {
  superuser = false
}

# Example: Create a database
resource "postgresql_database" "db" {
  name     = "test"
  # Use template1 instead of template0 (see https://www.postgresql.org/docs/current/manage-ag-templatedbs.html)
  template = "template1"
}

# Example: Create a role
resource "postgresql_role" "example_role" {
  name     = "example_role"
  login    = true
  password = "changeme"
}

# Example: Grant privileges
resource "postgresql_grant" "example_grant" {
  database    = postgresql_database.db.name
  role        = postgresql_role.example_role.name
  object_type = "database"
  privileges  = ["CREATE", "CONNECT", "TEMPORARY"]
}

