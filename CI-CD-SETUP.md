# 🚀 CI/CD Pipeline Setup Guide

This guide will help you set up the complete CI/CD pipeline for your Terraform infrastructure.

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [GitHub Repository Setup](#github-repository-setup)
3. [AWS OIDC Configuration](#aws-oidc-configuration)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Environment Protection Rules](#environment-protection-rules)
6. [Workflow Overview](#workflow-overview)
7. [Usage Guide](#usage-guide)
8. [Troubleshooting](#troubleshooting)

---

## ✅ Prerequisites

Before starting, ensure you have:
- ✅ GitHub repository with your Terraform code
- ✅ AWS account with admin access
- ✅ GitHub account with repository admin access
- ✅ Terraform Cloud/Enterprise account (optional, for remote state)

---

## 🔧 GitHub Repository Setup

### Step 1: Push Your Code to GitHub

```bash
# If you haven't initialized git yet
cd "c:\Users\Theophilus Kgopa\3tier-aws-infrastructure"
git init
git add .
git commit -m "Initial commit with CI/CD pipelines"

# Add your GitHub repository as remote
git remote add origin https://github.com/YOUR_USERNAME/terraform-3tier-aws-infrastructure.git
git branch -M main
git push -u origin main
```

### Step 2: Create Environment Branches

```bash
# Create dev branch
git checkout -b dev
git push -u origin dev

# Create staging branch
git checkout -b staging
git push -u origin staging

# Create prod branch
git checkout -b prod
git push -u origin prod

# Return to main
git checkout main
```

---

## 🔐 AWS OIDC Configuration

### Why OIDC?
Instead of storing long-lived AWS credentials in GitHub, we use OpenID Connect (OIDC) for secure, temporary credentials.

### Step 1: Create OIDC Provider in AWS

Run this AWS CloudFormation template or use the AWS Console:

```bash
# Create OIDC provider using AWS CLI
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 2: Create IAM Roles for Each Environment

Create three IAM roles (one for each environment):

**For DEV Environment:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/terraform-3tier-aws-infrastructure:*"
        }
      }
    }
  ]
}
```

**Attach this policy to the role:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "rds:*",
        "s3:*",
        "dynamodb:*",
        "iam:*",
        "kms:*",
        "logs:*",
        "cloudwatch:*"
      ],
      "Resource": "*"
    }
  ]
}
```

**Create roles using AWS CLI:**

```bash
# Create role for DEV
aws iam create-role \
  --role-name GitHubActions-Terraform-Dev \
  --assume-role-policy-document file://trust-policy-dev.json

# Attach policy
aws iam attach-role-policy \
  --role-name GitHubActions-Terraform-Dev \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Repeat for STAGING and PROD
```

---

## 🔑 GitHub Secrets Configuration

### Step 1: Navigate to Repository Settings

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**

### Step 2: Add Repository Secrets

Add these secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AWS_ROLE_ARN_DEV` | `arn:aws:iam::ACCOUNT_ID:role/GitHubActions-Terraform-Dev` | IAM role for dev |
| `AWS_ROLE_ARN_STAGING` | `arn:aws:iam::ACCOUNT_ID:role/GitHubActions-Terraform-Staging` | IAM role for staging |
| `AWS_ROLE_ARN_PROD` | `arn:aws:iam::ACCOUNT_ID:role/GitHubActions-Terraform-Prod` | IAM role for prod |
| `INFRACOST_API_KEY` | `ico-xxx...` | Get from [infracost.io](https://www.infracost.io/) |

### Step 3: (Optional) Add Notification Webhooks

| Secret Name | Value | Description |
|------------|-------|-------------|
| `SLACK_WEBHOOK` | `https://hooks.slack.com/...` | For Slack notifications |
| `TEAMS_WEBHOOK` | `https://outlook.office.com/...` | For Teams notifications |

---

## 🛡️ Environment Protection Rules

### Step 1: Create Environments

1. Go to **Settings** → **Environments**
2. Click **New environment**

Create these environments:
- `dev`
- `staging`
- `production-plan`
- `production`

### Step 2: Configure DEV Environment

- **Protection rules:** None (auto-deploy)
- **Environment secrets:** None needed

### Step 3: Configure STAGING Environment

- ✅ **Required reviewers:** Add 1-2 team members
- ✅ **Wait timer:** 5 minutes (optional)
- ✅ **Deployment branches:** `staging` only

### Step 4: Configure PRODUCTION Environment

- ✅ **Required reviewers:** Add 2-3 senior team members
- ✅ **Wait timer:** 10 minutes
- ✅ **Deployment branches:** `main` and `prod` only
- ✅ **Prevent self-review:** Enabled

### Step 5: Configure PRODUCTION-PLAN Environment

- ✅ **Required reviewers:** Add 1 team member
- ✅ **Deployment branches:** `main` and `prod` only

---

## 📊 Workflow Overview

### Workflow Files Created

```
.github/workflows/
├── terraform-ci.yml           # Security & quality checks
├── terraform-cd-dev.yml       # Auto-deploy to DEV
├── terraform-cd-staging.yml   # Manual deploy to STAGING
└── terraform-cd-prod.yml      # Manual deploy to PROD (with RBAC)
```

### Workflow Triggers

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **terraform-ci.yml** | PR to any branch | Run security scans, linting, validation |
| **terraform-cd-dev.yml** | Push to `dev` branch | Auto-deploy to DEV |
| **terraform-cd-staging.yml** | Push to `staging` branch | Deploy to STAGING (with approval) |
| **terraform-cd-prod.yml** | Push to `main` or `prod` | Deploy to PROD (with senior approval) |

---

## 🎯 Usage Guide

### Scenario 1: Making Changes to DEV

```bash
# Create a feature branch
git checkout dev
git checkout -b feature/add-new-instance

# Make your changes
# Edit Terraform files...

# Commit and push
git add .
git commit -m "Add new EC2 instance"
git push origin feature/add-new-instance

# Create PR to dev branch
# CI checks will run automatically
# Once approved and merged, auto-deploys to DEV
```

### Scenario 2: Promoting to STAGING

```bash
# Merge dev to staging
git checkout staging
git merge dev
git push origin staging

# Workflow triggers:
# 1. Plan runs automatically
# 2. Waits for manual approval
# 3. Apply runs after approval
# 4. Health checks run
```

### Scenario 3: Deploying to PRODUCTION

```bash
# Merge staging to main (or prod)
git checkout main
git merge staging
git push origin main

# Workflow triggers:
# 1. Security re-check runs
# 2. Plan runs (requires approval)
# 3. Waits for senior approval
# 4. Apply runs after approval
# 5. Comprehensive health checks
# 6. Notifications sent
```

### Manual Workflow Trigger

You can also trigger workflows manually:

1. Go to **Actions** tab
2. Select workflow (e.g., "Terraform CD - Deploy to PRODUCTION")
3. Click **Run workflow**
4. Select branch
5. Click **Run workflow**

---

## 🔍 What Each Workflow Does

### 1. **terraform-ci.yml** (Security & Quality)

**Runs on:** Every PR and push

**Jobs:**
- ✅ **Terraform Format Check** - Ensures code is formatted
- ✅ **Terraform Validation** - Validates syntax
- ✅ **Security Scan (tfsec)** - Checks for security issues
- ✅ **Security Scan (Checkov)** - Additional security checks
- ✅ **Terraform Lint** - Code quality checks
- ✅ **Cost Estimation** - Shows cost impact

**Example Output:**
```
✅ Format Check: Passed
✅ Validation: Passed
✅ tfsec: No issues found
✅ Checkov: 45 checks passed
✅ TFLint: No issues
💰 Cost: +$127.50/month
```

### 2. **terraform-cd-dev.yml** (DEV Deployment)

**Runs on:** Push to `dev` branch

**Jobs:**
1. **Plan DEV** - Creates Terraform plan
2. **Apply DEV** - Auto-applies changes
3. **Health Check** - Verifies infrastructure

**No approval needed** - Auto-deploys!

### 3. **terraform-cd-staging.yml** (STAGING Deployment)

**Runs on:** Push to `staging` branch

**Jobs:**
1. **Plan STAGING** - Creates plan
2. **Apply STAGING** - Waits for approval, then applies
3. **Health Check** - Comprehensive checks

**Requires:** 1-2 team member approvals

### 4. **terraform-cd-prod.yml** (PRODUCTION Deployment)

**Runs on:** Push to `main` or `prod` branch

**Jobs:**
1. **Security Re-check** - Extra security validation
2. **Plan PRODUCTION** - Creates plan (requires approval)
3. **Apply PRODUCTION** - Waits for senior approval
4. **Health Check** - Extensive health checks
5. **Notify Success/Failure** - Sends notifications

**Requires:** 2-3 senior team member approvals

---

## 🔧 Customization

### Adjust Security Scan Severity

Edit `.github/workflows/terraform-ci.yml`:

```yaml
# For stricter checks
additional_args: --minimum-severity LOW

# For less strict (not recommended)
additional_args: --minimum-severity HIGH
```

### Add Slack Notifications

Edit `.github/workflows/terraform-cd-prod.yml`:

```yaml
- name: Send Success Notification
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -H 'Content-Type: application/json' \
      -d '{
        "text": "✅ Production deployment successful!",
        "username": "Terraform Bot",
        "icon_emoji": ":rocket:"
      }'
```

### Modify Health Checks

Add custom health checks in the `health-check-*` jobs:

```yaml
- name: Custom Health Check
  run: |
    # Your custom health check logic
    curl -f https://your-app.com/health
```

---

## 🐛 Troubleshooting

### Issue: "Error: No valid credential sources found"

**Solution:** Check that:
1. OIDC provider is created in AWS
2. IAM role trust policy includes your repository
3. GitHub secret `AWS_ROLE_ARN_*` is correct

### Issue: "Terraform plan failed"

**Solution:**
1. Check Terraform syntax locally: `terraform validate`
2. Review the plan output in the workflow logs
3. Ensure backend is configured correctly

### Issue: "Security scan failed"

**Solution:**
1. Review tfsec/Checkov output
2. Fix security issues or add exceptions:
   ```yaml
   skip_check: CKV_AWS_79,CKV_AWS_23
   ```

### Issue: "Approval not showing up"

**Solution:**
1. Ensure environment is created in GitHub
2. Check that required reviewers are added
3. Verify deployment branch restrictions

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS OIDC with GitHub](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [tfsec Documentation](https://aquasecurity.github.io/tfsec/)
- [Checkov Documentation](https://www.checkov.io/)

---

## 🎉 You're All Set!

Your CI/CD pipeline is now configured with:
- ✅ Automated security scanning
- ✅ Code quality checks
- ✅ Auto-deployment to DEV
- ✅ Manual approvals for STAGING/PROD
- ✅ RBAC for production deployments
- ✅ Comprehensive health checks
- ✅ Cost estimation

**Next Steps:**
1. Complete AWS OIDC setup
2. Add GitHub secrets
3. Configure environment protection rules
4. Make a test change and create a PR
5. Watch the magic happen! 🚀
