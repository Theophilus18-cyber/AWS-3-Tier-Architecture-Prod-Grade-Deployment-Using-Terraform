# 🚀 Quick Start Guide - CI/CD Pipeline

This is a simplified guide to get your CI/CD pipeline running quickly.

## ⚡ 5-Minute Setup

### Step 1: Run the AWS Setup Script (Windows)

```powershell
# Navigate to your project
cd "c:\Users\Theophilus Kgopa\3tier-aws-infrastructure"

# Run the setup script
.\scripts\setup-aws-oidc.ps1
```

**What it does:**
- Creates AWS OIDC provider
- Creates 3 IAM roles (Dev, Staging, Prod)
- Gives you the ARNs to add to GitHub

### Step 2: Add Secrets to GitHub

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
2. Click **"New repository secret"**
3. Add these three secrets (copy from script output):

```
Name: AWS_ROLE_ARN_DEV
Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-Terraform-Dev

Name: AWS_ROLE_ARN_STAGING
Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-Terraform-Staging

Name: AWS_ROLE_ARN_PROD
Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-Terraform-Prod
```

### Step 3: (Optional) Get Infracost API Key

1. Go to: https://www.infracost.io/
2. Sign up (free)
3. Get your API key
4. Add to GitHub secrets:

```
Name: INFRACOST_API_KEY
Value: ico-xxxxxxxxxxxxx
```

### Step 4: Create GitHub Environments

1. Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/environments`
2. Create these environments:

**dev:**
- No protection rules
- Click "Configure environment" → Save

**staging:**
- Required reviewers: Add yourself or team members
- Click "Configure environment" → Save

**production-plan:**
- Required reviewers: Add 1 reviewer
- Click "Configure environment" → Save

**production:**
- Required reviewers: Add 2+ senior reviewers
- Wait timer: 10 minutes
- Deployment branches: Only `main` and `prod`
- Click "Configure environment" → Save

### Step 5: Push Your Code

```bash
# Initialize git (if not already done)
git init
git add .
git commit -m "Add CI/CD pipelines"

# Add your GitHub repo
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to main
git branch -M main
git push -u origin main

# Create environment branches
git checkout -b dev
git push -u origin dev

git checkout -b staging
git push -u origin staging

git checkout -b prod
git push -u origin prod

git checkout main
```

---

## 🎯 How to Use

### Making Changes

```bash
# 1. Create a feature branch from dev
git checkout dev
git pull
git checkout -b feature/my-change

# 2. Make your changes
# Edit your .tf files...

# 3. Commit and push
git add .
git commit -m "Add new feature"
git push origin feature/my-change

# 4. Create Pull Request to dev branch
# - Go to GitHub
# - Create PR from feature/my-change → dev
# - CI checks will run automatically
# - Review the security scan results
# - Merge when ready

# 5. Auto-deploys to DEV!
# - When merged to dev, automatically deploys
# - Check Actions tab to see progress
```

### Promoting to Staging

```bash
# Merge dev to staging
git checkout staging
git pull
git merge dev
git push origin staging

# Workflow will:
# 1. Run plan
# 2. Wait for your approval
# 3. Deploy after approval
# 4. Run health checks
```

### Deploying to Production

```bash
# Merge staging to main
git checkout main
git pull
git merge staging
git push origin main

# Workflow will:
# 1. Run security re-check
# 2. Create plan (requires approval)
# 3. Wait for senior approvals
# 4. Deploy after approvals
# 5. Run comprehensive health checks
# 6. Send notifications
```

---

## 📊 What Happens in Each Stage

### On Pull Request (Any Branch)
```
✅ Terraform format check
✅ Terraform validation
✅ Security scan (tfsec)
✅ Security scan (Checkov)
✅ Linting (tflint)
✅ Cost estimation
```

### On Merge to `dev`
```
✅ All CI checks
✅ Terraform plan
✅ Auto-deploy to DEV
✅ Health checks
```

### On Merge to `staging`
```
✅ All CI checks
✅ Terraform plan
⏸️  Wait for approval
✅ Deploy to STAGING
✅ Health checks
```

### On Merge to `main`/`prod`
```
✅ Security re-validation
✅ Terraform plan
⏸️  Wait for senior approval
✅ Deploy to PRODUCTION
✅ Comprehensive health checks
✅ Notifications
```

---

## 🔍 Monitoring Your Pipelines

### View Workflow Runs

1. Go to your GitHub repository
2. Click **Actions** tab
3. See all workflow runs

### Check Deployment Status

Each workflow run shows:
- ✅ Which jobs passed
- ❌ Which jobs failed
- ⏸️ Which jobs are waiting for approval
- 📊 Summary of changes

### Approve Deployments

When a deployment needs approval:
1. Go to **Actions** tab
2. Click on the workflow run
3. Click **Review deployments**
4. Select environment
5. Click **Approve and deploy**

---

## 🐛 Common Issues

### "No valid credential sources found"

**Fix:** Make sure you added the AWS role ARNs to GitHub secrets correctly.

### "Terraform backend initialization failed"

**Fix:** Ensure your S3 backend is configured and accessible.

### "Security scan failed"

**Fix:** Review the security issues and fix them, or add exceptions if they're false positives.

### "Approval not showing"

**Fix:** Make sure you created the environments in GitHub settings.

---

## 📚 Full Documentation

For detailed information, see: [CI-CD-SETUP.md](./CI-CD-SETUP.md)

---

## 🎉 You're Done!

Your CI/CD pipeline is now ready! 

**Test it:**
1. Make a small change to a `.tf` file
2. Create a PR to `dev`
3. Watch the CI checks run
4. Merge and watch it auto-deploy!

**Questions?** Check the full setup guide or the workflow files in `.github/workflows/`
