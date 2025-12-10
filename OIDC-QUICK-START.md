# 🚀 Quick Start: AWS OIDC Setup

This is a **quick reference guide** for setting up AWS OIDC for GitHub Actions. For detailed instructions, see [AWS-OIDC-SETUP-GUIDE.md](./AWS-OIDC-SETUP-GUIDE.md).

## ⚡ Option 1: Automated Setup (Recommended)

### For Windows (PowerShell):
```powershell
cd scripts
.\setup-oidc.ps1
```

### For Linux/Mac (Bash):
```bash
cd scripts
chmod +x setup-oidc.sh
./setup-oidc.sh
```

The script will:
1. ✅ Create OIDC provider in AWS
2. ✅ Create IAM roles for dev, staging, and prod
3. ✅ Attach necessary policies
4. ✅ Display the ARNs you need to add to GitHub

## ⚡ Option 2: Manual Setup

### Step 1: Create OIDC Provider
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 2: Get Your Info
```bash
# Get AWS Account ID
aws sts get-caller-identity --query Account --output text

# Note your GitHub username and repo name
# Example: Theophilus18-cyber/AWS-3-Tier-Architecture-Prod-Grade-Deployment-Using-Terraform
```

### Step 3: Create Trust Policy Files

Create `trust-policy-dev.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/YOUR_REPO:ref:refs/heads/dev"
      }
    }
  }]
}
```

**Replace:**
- `YOUR_ACCOUNT_ID` with your AWS account ID
- `YOUR_USERNAME/YOUR_REPO` with your GitHub repository

Create similar files for staging and prod (change `dev` to `staging` and `main`).

### Step 4: Create IAM Roles
```bash
# Create DEV role
aws iam create-role \
  --role-name GitHubActions-Terraform-Dev \
  --assume-role-policy-document file://trust-policy-dev.json

aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Dev \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Repeat for STAGING and PROD
```

### Step 5: Get Role ARNs
```bash
aws iam get-role --role-name GitHubActions-Terraform-Dev --query 'Role.Arn' --output text
aws iam get-role --role-name GitHubActions-Terraform-Staging --query 'Role.Arn' --output text
aws iam get-role --role-name GitHubActions-Terraform-Prod --query 'Role.Arn' --output text
```

## 🔐 Add Secrets to GitHub

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Add these three secrets:

| Secret Name | Value |
|------------|-------|
| `AWS_ROLE_ARN_DEV` | `arn:aws:iam::ACCOUNT_ID:role/GitHubActions-Terraform-Dev` |
| `AWS_ROLE_ARN_STAGING` | `arn:aws:iam::ACCOUNT_ID:role/GitHubActions-Terraform-Staging` |
| `AWS_ROLE_ARN_PROD` | `arn:aws:iam::ACCOUNT_ID:role/GitHubActions-Terraform-Prod` |

## ✅ Verify Setup

### For Windows:
```powershell
cd scripts
.\verify-oidc.ps1
```

### For Linux/Mac:
```bash
cd scripts
chmod +x verify-oidc.sh
./verify-oidc.sh
```

## 🧪 Test the Setup

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select any workflow (e.g., "Terraform CD - Deploy to DEV")
4. Click **Run workflow**
5. If it succeeds, OIDC is working! 🎉

## 📚 Additional Resources

- **Detailed Guide**: [AWS-OIDC-SETUP-GUIDE.md](./AWS-OIDC-SETUP-GUIDE.md)
- **CI/CD Setup**: [CI-CD-SETUP.md](./CI-CD-SETUP.md)
- **Pipeline Architecture**: [PIPELINE-ARCHITECTURE.md](./PIPELINE-ARCHITECTURE.md)

## 🐛 Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"
- Check that your repository name in the trust policy is correct
- Verify you're running from the correct branch (dev/staging/main)

### Error: "OpenIDConnect provider not found"
- Run the OIDC provider creation command again
- Verify with: `aws iam list-open-id-connect-providers`

### Error: "Access Denied"
- Ensure AdministratorAccess policy is attached to the role
- Verify with: `aws iam list-attached-role-policies --role-name GitHubActions-Terraform-Dev`

## 🎯 Next Steps

After OIDC is set up:

1. ✅ Configure GitHub Environments (see [CI-CD-SETUP.md](./CI-CD-SETUP.md#environment-protection-rules))
2. ✅ Set up branch protection rules
3. ✅ Add team members as reviewers
4. ✅ Test the full CI/CD pipeline

---

**Need help?** See the [detailed guide](./AWS-OIDC-SETUP-GUIDE.md) or check the [troubleshooting section](./AWS-OIDC-SETUP-GUIDE.md#troubleshooting).
