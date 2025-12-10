# 🔐 AWS OIDC Setup Guide for GitHub Actions

This guide provides **step-by-step instructions** to set up OpenID Connect (OIDC) authentication between GitHub Actions and AWS for your 3-tier infrastructure project.

## 📋 Table of Contents
1. [What is OIDC and Why Use It?](#what-is-oidc-and-why-use-it)
2. [Prerequisites](#prerequisites)
3. [Step 1: Create OIDC Identity Provider in AWS](#step-1-create-oidc-identity-provider-in-aws)
4. [Step 2: Create IAM Roles for Each Environment](#step-2-create-iam-roles-for-each-environment)
5. [Step 3: Configure GitHub Secrets](#step-3-configure-github-secrets)
6. [Step 4: Test the Setup](#step-4-test-the-setup)
7. [Troubleshooting](#troubleshooting)

---

## 🤔 What is OIDC and Why Use It?

### Traditional Approach (❌ Not Recommended)
- Store AWS Access Keys as GitHub secrets
- Long-lived credentials that can be compromised
- Manual rotation required
- Broad permissions that can't be scoped to specific branches

### OIDC Approach (✅ Recommended)
- No long-lived credentials stored in GitHub
- Temporary credentials (valid for 1 hour)
- Automatic credential rotation
- Can scope permissions to specific repositories and branches
- Follows AWS security best practices

### How It Works
```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────┐
│  GitHub Actions │────────▶│  GitHub OIDC     │────────▶│     AWS     │
│   Workflow      │  Request│  Token Provider  │  Verify │  IAM Role   │
└─────────────────┘   Token └──────────────────┘  Token  └─────────────┘
                                                              │
                                                              ▼
                                                    Temporary Credentials
                                                    (Valid for 1 hour)
```

---

## ✅ Prerequisites

Before you begin, ensure you have:

- ✅ **AWS Account** with administrative access
- ✅ **AWS CLI** installed and configured ([Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- ✅ **GitHub Repository** with your Terraform code
- ✅ **GitHub Repository Admin Access** to configure secrets
- ✅ **Your GitHub Username** (e.g., `Theophilus18-cyber`)
- ✅ **Your Repository Name** (e.g., `AWS-3-Tier-Architecture-Prod-Grade-Deployment-Using-Terraform`)

---

## 🚀 Step 1: Create OIDC Identity Provider in AWS

The OIDC Identity Provider allows AWS to trust tokens issued by GitHub.

### Option A: Using AWS Console (Recommended for Beginners)

1. **Navigate to IAM Console**
   - Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)
   - Click **Identity providers** in the left sidebar
   - Click **Add provider**

2. **Configure Provider**
   - **Provider type**: Select `OpenID Connect`
   - **Provider URL**: Enter `https://token.actions.githubusercontent.com`
   - Click **Get thumbprint** (it should auto-populate)
   - **Audience**: Enter `sts.amazonaws.com`
   - Click **Add provider**

3. **Verify Creation**
   - You should see the provider listed as `token.actions.githubusercontent.com`

### Option B: Using AWS CLI (Faster)

```bash
# Create the OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

**Expected Output:**
```json
{
    "OpenIDConnectProviderArn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}
```

**✅ Checkpoint:** Verify the provider was created:
```bash
aws iam list-open-id-connect-providers
```

---

## 🔑 Step 2: Create IAM Roles for Each Environment

You need to create **three separate IAM roles** (one for each environment: dev, staging, prod).

### Important Information You'll Need

Before proceeding, gather this information:

1. **Your AWS Account ID**: 
   ```bash
   aws sts get-caller-identity --query Account --output text
   ```

2. **Your GitHub Repository Full Name**: 
   - Format: `YOUR_USERNAME/YOUR_REPO_NAME`
   - Example: `Theophilus18-cyber/AWS-3-Tier-Architecture-Prod-Grade-Deployment-Using-Terraform`

### Step 2.1: Create Trust Policy Documents

Create three JSON files for the trust policies:

#### **File 1: `trust-policy-dev.json`**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:ref:refs/heads/dev"
        }
      }
    }
  ]
}
```

#### **File 2: `trust-policy-staging.json`**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:ref:refs/heads/staging"
        }
      }
    }
  ]
}
```

#### **File 3: `trust-policy-prod.json`**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

**🔧 Important:** Replace the following placeholders in ALL three files:
- `YOUR_AWS_ACCOUNT_ID` → Your actual AWS account ID (e.g., `123456789012`)
- `YOUR_GITHUB_USERNAME` → Your GitHub username (e.g., `Theophilus18-cyber`)
- `YOUR_REPO_NAME` → Your repository name (e.g., `AWS-3-Tier-Architecture-Prod-Grade-Deployment-Using-Terraform`)

### Step 2.2: Create the IAM Roles

#### Create DEV Role

```bash
# Create the role
aws iam create-role \
  --role-name GitHubActions-Terraform-Dev \
  --assume-role-policy-document file://trust-policy-dev.json \
  --description "Role for GitHub Actions to deploy to DEV environment"

# Attach AdministratorAccess policy (or create a custom policy)
aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Dev \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### Create STAGING Role

```bash
# Create the role
aws iam create-role \
  --role-name GitHubActions-Terraform-Staging \
  --assume-role-policy-document file://trust-policy-staging.json \
  --description "Role for GitHub Actions to deploy to STAGING environment"

# Attach AdministratorAccess policy
aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Staging \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### Create PROD Role

```bash
# Create the role
aws iam create-role \
  --role-name GitHubActions-Terraform-Prod \
  --assume-role-policy-document file://trust-policy-prod.json \
  --description "Role for GitHub Actions to deploy to PRODUCTION environment"

# Attach AdministratorAccess policy
aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Prod \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Step 2.3: Get the Role ARNs

You'll need these ARNs for GitHub secrets:

```bash
# Get DEV role ARN
aws iam get-role --role-name GitHubActions-Terraform-Dev --query 'Role.Arn' --output text

# Get STAGING role ARN
aws iam get-role --role-name GitHubActions-Terraform-Staging --query 'Role.Arn' --output text

# Get PROD role ARN
aws iam get-role --role-name GitHubActions-Terraform-Prod --query 'Role.Arn' --output text
```

**📝 Save these ARNs!** They will look like:
```
arn:aws:iam::123456789012:role/GitHubActions-Terraform-Dev
arn:aws:iam::123456789012:role/GitHubActions-Terraform-Staging
arn:aws:iam::123456789012:role/GitHubActions-Terraform-Prod
```

---

## 🔐 Step 3: Configure GitHub Secrets

Now you need to add the IAM Role ARNs as secrets in your GitHub repository.

### Step 3.1: Navigate to GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** (top right)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Step 3.2: Add the Secrets

Add these three secrets:

| Secret Name | Value | Example |
|------------|-------|---------|
| `AWS_ROLE_ARN_DEV` | ARN of DEV role | `arn:aws:iam::123456789012:role/GitHubActions-Terraform-Dev` |
| `AWS_ROLE_ARN_STAGING` | ARN of STAGING role | `arn:aws:iam::123456789012:role/GitHubActions-Terraform-Staging` |
| `AWS_ROLE_ARN_PROD` | ARN of PROD role | `arn:aws:iam::123456789012:role/GitHubActions-Terraform-Prod` |

**For each secret:**
1. Click **New repository secret**
2. Enter the **Name** (e.g., `AWS_ROLE_ARN_DEV`)
3. Paste the **Value** (the ARN you copied earlier)
4. Click **Add secret**

### Step 3.3: Verify Secrets

After adding all three secrets, you should see them listed (values will be hidden):
- ✅ `AWS_ROLE_ARN_DEV`
- ✅ `AWS_ROLE_ARN_STAGING`
- ✅ `AWS_ROLE_ARN_PROD`

---

## 🧪 Step 4: Test the Setup

Let's verify that OIDC authentication is working correctly.

### Step 4.1: Create Test Workflow

Create a test workflow file: `.github/workflows/test-oidc.yml`

```yaml
name: Test OIDC Authentication

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  test-dev:
    name: Test DEV OIDC
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_DEV }}
          aws-region: us-east-1

      - name: Verify AWS Identity
        run: |
          echo "✅ Successfully authenticated with AWS!"
          aws sts get-caller-identity
          
      - name: Test AWS Permissions
        run: |
          echo "Testing AWS permissions..."
          aws ec2 describe-regions --output table
```

### Step 4.2: Run the Test

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Test OIDC Authentication** workflow
4. Click **Run workflow** → **Run workflow**
5. Wait for the workflow to complete

**Expected Result:**
- ✅ Workflow should complete successfully
- ✅ You should see your AWS account details
- ✅ You should see a list of AWS regions

**If it fails**, see the [Troubleshooting](#troubleshooting) section below.

---

## 🐛 Troubleshooting

### Error: "Not authorized to perform sts:AssumeRoleWithWebIdentity"

**Cause:** Trust policy doesn't match your repository or branch.

**Solution:**
1. Verify your repository name is correct in the trust policy
2. Ensure you're running from the correct branch (dev/staging/main)
3. Check that the OIDC provider ARN in the trust policy matches your account

**Verify trust policy:**
```bash
aws iam get-role --role-name GitHubActions-Terraform-Dev --query 'Role.AssumeRolePolicyDocument'
```

### Error: "OpenIDConnect provider not found"

**Cause:** OIDC provider wasn't created or was created in a different region.

**Solution:**
```bash
# List all OIDC providers
aws iam list-open-id-connect-providers

# If empty, create the provider again
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Error: "Error: Could not assume role with OIDC"

**Cause:** GitHub secret is incorrect or missing.

**Solution:**
1. Go to GitHub Settings → Secrets and variables → Actions
2. Verify the secret name matches exactly: `AWS_ROLE_ARN_DEV`
3. Verify the ARN value is correct
4. Re-create the secret if needed

### Error: "Access Denied" when running Terraform

**Cause:** IAM role doesn't have sufficient permissions.

**Solution:**
```bash
# Check attached policies
aws iam list-attached-role-policies --role-name GitHubActions-Terraform-Dev

# If AdministratorAccess is not attached, attach it
aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Dev \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Verify Complete Setup

Run this verification script:

```bash
#!/bin/bash
echo "🔍 Verifying OIDC Setup..."
echo ""

# Check OIDC Provider
echo "1. Checking OIDC Provider..."
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com && echo "✅ OIDC Provider exists" || echo "❌ OIDC Provider NOT found"
echo ""

# Check IAM Roles
echo "2. Checking IAM Roles..."
aws iam get-role --role-name GitHubActions-Terraform-Dev &>/dev/null && echo "✅ DEV role exists" || echo "❌ DEV role NOT found"
aws iam get-role --role-name GitHubActions-Terraform-Staging &>/dev/null && echo "✅ STAGING role exists" || echo "❌ STAGING role NOT found"
aws iam get-role --role-name GitHubActions-Terraform-Prod &>/dev/null && echo "✅ PROD role exists" || echo "❌ PROD role NOT found"
echo ""

# Display Role ARNs
echo "3. Role ARNs (add these to GitHub secrets):"
echo "AWS_ROLE_ARN_DEV:"
aws iam get-role --role-name GitHubActions-Terraform-Dev --query 'Role.Arn' --output text
echo "AWS_ROLE_ARN_STAGING:"
aws iam get-role --role-name GitHubActions-Terraform-Staging --query 'Role.Arn' --output text
echo "AWS_ROLE_ARN_PROD:"
aws iam get-role --role-name GitHubActions-Terraform-Prod --query 'Role.Arn' --output text
```

---

## 🎯 Next Steps

After completing this setup:

1. ✅ **Test your workflows**: Create a feature branch and open a PR to test CI
2. ✅ **Set up GitHub Environments**: Configure protection rules (see [CI-CD-SETUP.md](./CI-CD-SETUP.md))
3. ✅ **Configure branch protection**: Protect main, staging, and dev branches
4. ✅ **Add team members**: Add reviewers for staging and production approvals
5. ✅ **Test deployments**: Try deploying to dev, then staging, then production

---

## 📚 Additional Resources

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

---

## 🔒 Security Best Practices

1. **Use least-privilege permissions**: Instead of `AdministratorAccess`, create custom policies with only required permissions
2. **Scope to specific branches**: Trust policies already limit access to specific branches
3. **Enable CloudTrail**: Monitor all AWS API calls made by GitHub Actions
4. **Rotate nothing**: OIDC tokens are temporary and auto-rotate
5. **Review regularly**: Audit IAM roles and their usage quarterly

---

## ✅ Checklist

Use this checklist to track your progress:

- [ ] OIDC Provider created in AWS
- [ ] Trust policy files created for all three environments
- [ ] DEV IAM role created
- [ ] STAGING IAM role created
- [ ] PROD IAM role created
- [ ] Policies attached to all roles
- [ ] Role ARNs copied
- [ ] `AWS_ROLE_ARN_DEV` secret added to GitHub
- [ ] `AWS_ROLE_ARN_STAGING` secret added to GitHub
- [ ] `AWS_ROLE_ARN_PROD` secret added to GitHub
- [ ] Test workflow created and run successfully
- [ ] Verification script run successfully

---

**🎉 Congratulations!** You've successfully set up AWS OIDC for GitHub Actions. Your CI/CD pipeline can now securely authenticate with AWS without storing long-lived credentials.
