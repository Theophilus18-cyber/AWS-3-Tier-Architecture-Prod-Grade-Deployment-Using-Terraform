# ✅ CI/CD Pipeline Setup Checklist

Use this checklist to ensure you've completed all setup steps.

## 📋 Pre-Setup Checklist

- [ ] I have a GitHub account
- [ ] I have AWS account access
- [ ] I have AWS CLI installed and configured
- [ ] I have Git installed
- [ ] My Terraform code is in this repository
- [ ] I understand the pipeline flow (see PIPELINE-ARCHITECTURE.md)

---

## 🔧 Step 1: AWS OIDC Setup

- [ ] Run the setup script:
  ```powershell
  .\scripts\setup-aws-oidc.ps1
  ```
- [ ] Script completed successfully
- [ ] I have copied the 3 IAM role ARNs
- [ ] OIDC provider created in AWS
- [ ] IAM roles created:
  - [ ] GitHubActions-Terraform-Dev
  - [ ] GitHubActions-Terraform-Staging
  - [ ] GitHubActions-Terraform-Prod

**ARNs to save:**
```
AWS_ROLE_ARN_DEV: _______________________________________________
AWS_ROLE_ARN_STAGING: ___________________________________________
AWS_ROLE_ARN_PROD: ______________________________________________
```

---

## 🔑 Step 2: GitHub Secrets

- [ ] Navigate to: `https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions`
- [ ] Add secret: `AWS_ROLE_ARN_DEV`
- [ ] Add secret: `AWS_ROLE_ARN_STAGING`
- [ ] Add secret: `AWS_ROLE_ARN_PROD`
- [ ] (Optional) Get Infracost API key from https://www.infracost.io/
- [ ] (Optional) Add secret: `INFRACOST_API_KEY`
- [ ] (Optional) Add secret: `SLACK_WEBHOOK` (for notifications)

---

## 🛡️ Step 3: GitHub Environments

### Create DEV Environment
- [ ] Go to: `Settings → Environments → New environment`
- [ ] Name: `dev`
- [ ] Protection rules: None
- [ ] Click "Configure environment"
- [ ] Click "Save protection rules"

### Create STAGING Environment
- [ ] Go to: `Settings → Environments → New environment`
- [ ] Name: `staging`
- [ ] Enable "Required reviewers"
- [ ] Add 1-2 team members as reviewers
- [ ] (Optional) Set wait timer: 5 minutes
- [ ] Deployment branches: `Selected branches` → Add `staging`
- [ ] Click "Save protection rules"

### Create PRODUCTION-PLAN Environment
- [ ] Go to: `Settings → Environments → New environment`
- [ ] Name: `production-plan`
- [ ] Enable "Required reviewers"
- [ ] Add 1 senior team member as reviewer
- [ ] Deployment branches: `Selected branches` → Add `main` and `prod`
- [ ] Click "Save protection rules"

### Create PRODUCTION Environment
- [ ] Go to: `Settings → Environments → New environment`
- [ ] Name: `production`
- [ ] Enable "Required reviewers"
- [ ] Add 2-3 senior team members as reviewers
- [ ] Enable "Prevent self-review"
- [ ] Set wait timer: 10 minutes
- [ ] Deployment branches: `Selected branches` → Add `main` and `prod`
- [ ] Click "Save protection rules"

---

## 📤 Step 4: Push Code to GitHub

### Initialize Git (if not already done)
- [ ] Run: `git init`
- [ ] Run: `git add .`
- [ ] Run: `git commit -m "Add CI/CD pipeline"`

### Add GitHub Remote
- [ ] Create repository on GitHub (if not exists)
- [ ] Run: `git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git`
- [ ] Verify: `git remote -v`

### Push Main Branch
- [ ] Run: `git branch -M main`
- [ ] Run: `git push -u origin main`
- [ ] Verify: Check GitHub repository

### Create Environment Branches
- [ ] Run: `git checkout -b dev`
- [ ] Run: `git push -u origin dev`
- [ ] Run: `git checkout -b staging`
- [ ] Run: `git push -u origin staging`
- [ ] Run: `git checkout -b prod`
- [ ] Run: `git push -u origin prod`
- [ ] Run: `git checkout main`
- [ ] Verify: All branches exist on GitHub

---

## 🔒 Step 5: Branch Protection (Optional but Recommended)

### Protect Main Branch
- [ ] Go to: `Settings → Branches → Add branch protection rule`
- [ ] Branch name pattern: `main`
- [ ] Enable "Require a pull request before merging"
- [ ] Enable "Require approvals" (1-2 approvals)
- [ ] Enable "Require status checks to pass before merging"
- [ ] Select status checks: All CI checks
- [ ] Enable "Require branches to be up to date before merging"
- [ ] Enable "Include administrators"
- [ ] Click "Create"

### Protect Staging Branch
- [ ] Go to: `Settings → Branches → Add branch protection rule`
- [ ] Branch name pattern: `staging`
- [ ] Enable "Require a pull request before merging"
- [ ] Enable "Require approvals" (1 approval)
- [ ] Click "Create"

### Protect Dev Branch (Optional)
- [ ] Go to: `Settings → Branches → Add branch protection rule`
- [ ] Branch name pattern: `dev`
- [ ] Enable "Require a pull request before merging"
- [ ] Click "Create"

---

## 🧪 Step 6: Test the Pipeline

### Test CI Pipeline
- [ ] Create a feature branch: `git checkout -b feature/test-ci`
- [ ] Make a small change to a `.tf` file
- [ ] Commit: `git commit -am "Test CI pipeline"`
- [ ] Push: `git push origin feature/test-ci`
- [ ] Create PR to `dev` branch on GitHub
- [ ] Verify CI checks run:
  - [ ] Format check passes
  - [ ] Validation passes
  - [ ] Security scans pass
  - [ ] Linting passes
  - [ ] (Optional) Cost estimation shows
- [ ] Merge PR

### Test DEV Deployment
- [ ] After merging PR to dev, go to Actions tab
- [ ] Verify "Terraform CD - Deploy to DEV" workflow runs
- [ ] Check workflow steps:
  - [ ] Plan completes
  - [ ] Apply completes (auto)
  - [ ] Health checks pass
- [ ] Verify resources created in AWS

### Test STAGING Deployment
- [ ] Merge dev to staging: `git checkout staging && git merge dev && git push`
- [ ] Go to Actions tab
- [ ] Verify "Terraform CD - Deploy to STAGING" workflow runs
- [ ] Workflow pauses for approval
- [ ] Click "Review deployments"
- [ ] Approve deployment
- [ ] Verify deployment completes
- [ ] Check health checks pass

### Test PRODUCTION Deployment (Optional)
- [ ] Merge staging to main: `git checkout main && git merge staging && git push`
- [ ] Go to Actions tab
- [ ] Verify "Terraform CD - Deploy to PRODUCTION" workflow runs
- [ ] Security re-check passes
- [ ] Plan completes and waits for approval
- [ ] Multiple reviewers approve
- [ ] Wait timer completes
- [ ] Deployment completes
- [ ] Health checks pass
- [ ] Notifications sent (if configured)

---

## 📊 Step 7: Verify Everything Works

- [ ] All workflows are visible in Actions tab
- [ ] CI runs on pull requests
- [ ] DEV auto-deploys on merge
- [ ] STAGING requires approval
- [ ] PRODUCTION requires multiple approvals
- [ ] Health checks run after deployments
- [ ] AWS resources are created correctly
- [ ] Terraform state is managed properly

---

## 🎓 Step 8: Learn and Customize

- [ ] Read through PIPELINE-ARCHITECTURE.md
- [ ] Understand the workflow files in `.github/workflows/`
- [ ] Review security scan results
- [ ] Customize notification settings (Slack/Teams)
- [ ] Adjust approval requirements if needed
- [ ] Consider creating least-privilege IAM policies
- [ ] Enable TLS for Vault in production
- [ ] Set up monitoring and alerting

---

## 🔧 Troubleshooting Checklist

If something doesn't work:

- [ ] Check GitHub Actions logs for error messages
- [ ] Verify AWS credentials are correct
- [ ] Ensure IAM roles have correct trust policies
- [ ] Check that environments are created in GitHub
- [ ] Verify branch names match workflow triggers
- [ ] Ensure Terraform backend is configured
- [ ] Check that required secrets are added
- [ ] Review CI-CD-SETUP.md troubleshooting section

---

## 📝 Notes

Use this space for your own notes:

```
Date completed: _______________

Issues encountered:
_________________________________
_________________________________
_________________________________

Customizations made:
_________________________________
_________________________________
_________________________________

Team members added as reviewers:
_________________________________
_________________________________
_________________________________
```

---

## ✅ Final Verification

- [ ] I can create a PR and see CI checks run
- [ ] I can merge to dev and see auto-deployment
- [ ] I can deploy to staging with approval
- [ ] I can deploy to production with multiple approvals
- [ ] Health checks verify my infrastructure
- [ ] I understand how to rollback if needed
- [ ] My team knows how to approve deployments
- [ ] Documentation is accessible to my team

---

## 🎉 Congratulations!

If all items are checked, your CI/CD pipeline is fully operational!

**Next steps:**
1. Share documentation with your team
2. Train team members on approval process
3. Start using the pipeline for real deployments
4. Monitor and improve based on feedback

**Happy deploying! 🚀**
