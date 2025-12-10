# Bootstrapping Your Terraform State

This folder handles the "chicken and egg" problem. It creates the S3 bucket and DynamoDB table that we'll use to store the state for everything else. You only need to run this once.

## Usage
1. `terraform init`
2. `terraform apply`

---

##  Troubleshooting: Is `terraform init` freezing?

If you run `terraform init` and it just hangs at `Installing hashicorp/aws...` without moving, you're not crazy. This happens sometimes when Terraform gets stuck trying to verify digital signatures over a flakey network.

**Here is the "Silver Bullet" fix:**

Effectively, we need to tell Terraform to skip the paranoid security checks for now and just download the provider.

### Step 1: Create a Config File
Create a file at this path (or edit it if it exists):
`%APPDATA%\terraform.rc` 
*(Usually `C:\Users\YOUR_NAME\AppData\Roaming\terraform.rc`)*

Paste this content in. It tells Terraform to use a local cache and skip the signature check:

```hcl
provider_installation {
  filesystem_mirror {
    path    = "C:/terraform-provider-cache"
  }
  direct {
    disable_signature_verification = true
  }
}
```

### Step 2: Create the Cache Folder
Terraform needs that folder we just promised it in the config. Open PowerShell and run:

```powershell
mkdir C:\terraform-provider-cache
```

### Step 3: Try Again
Run this command to force it to re-read your config:

```bash
terraform init -upgrade
```

It should fly through the installation now. 
