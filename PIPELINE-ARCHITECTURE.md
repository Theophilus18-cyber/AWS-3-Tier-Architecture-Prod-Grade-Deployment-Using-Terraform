# CI/CD Pipeline Architecture

## 🔄 Complete Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKFLOW                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │  Create Feature Branch        │
                    │  Make Changes                 │
                    │  Push to GitHub               │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    STAGE 1: PULL REQUEST (CI)                            │
│  Trigger: PR to any branch                                              │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │   Format     │  │  Validation  │  │   Security   │                  │
│  │    Check     │  │              │  │  Scan (tfsec)│                  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                  │
│         │                 │                 │                           │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐                  │
│  │   Security   │  │   Linting    │  │     Cost     │                  │
│  │Scan(Checkov) │  │   (tflint)   │  │  Estimation  │                  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                  │
│         │                 │                 │                           │
│         └─────────────────┴─────────────────┘                           │
│                           │                                             │
│                    ✅ All Checks Pass                                    │
│                    ❌ Fix Issues                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                            Merge to dev branch
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    STAGE 2: DEV DEPLOYMENT (CD)                          │
│  Trigger: Push to dev branch                                            │
│  Approval: NONE (Auto-deploy)                                           │
├─────────────────────────────────────────────────────────────────────────┤
│  1. 📋 Terraform Plan                                                    │
│     ├─ Plan infrastructure changes                                      │
│     ├─ Plan Vault changes                                               │
│     └─ Upload plan artifacts                                            │
│                                                                          │
│  2. 🚀 Terraform Apply (AUTO)                                            │
│     ├─ Apply infrastructure                                             │
│     ├─ Apply Vault config                                               │
│     └─ Capture outputs                                                  │
│                                                                          │
│  3. 🏥 Health Checks                                                     │
│     ├─ Check EC2 instances                                              │
│     ├─ Check Vault health                                               │
│     └─ Generate summary                                                 │
│                                                                          │
│  ✅ DEV Environment Updated                                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                         Merge dev → staging
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                  STAGE 3: STAGING DEPLOYMENT (CD)                        │
│  Trigger: Push to staging branch                                        │
│  Approval: 1-2 Team Members Required                                    │
├─────────────────────────────────────────────────────────────────────────┤
│  1. 📋 Terraform Plan                                                    │
│     ├─ Plan infrastructure changes                                      │
│     ├─ Plan Vault changes                                               │
│     └─ Upload plan artifacts                                            │
│                                                                          │
│  2. ⏸️  WAIT FOR APPROVAL                                                │
│     ├─ Reviewer gets notification                                       │
│     ├─ Review plan in GitHub                                            │
│     └─ Approve or reject                                                │
│                                                                          │
│  3. 🚀 Terraform Apply (After Approval)                                  │
│     ├─ Apply infrastructure                                             │
│     ├─ Apply Vault config                                               │
│     └─ Capture outputs                                                  │
│                                                                          │
│  4. 🏥 Health Checks                                                     │
│     ├─ Check EC2 instances                                              │
│     ├─ Check Load Balancers                                             │
│     ├─ Check Target Groups                                              │
│     ├─ Check Vault health                                               │
│     ├─ Run integration tests                                            │
│     └─ Generate summary                                                 │
│                                                                          │
│  ✅ STAGING Environment Updated                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                       Merge staging → main
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                 STAGE 4: PRODUCTION DEPLOYMENT (CD)                      │
│  Trigger: Push to main/prod branch                                      │
│  Approval: 2-3 Senior Team Members + Wait Timer                         │
│  RBAC: Production-level permissions required                            │
├─────────────────────────────────────────────────────────────────────────┤
│  1. 🔒 Security Re-validation                                            │
│     ├─ Re-run tfsec (HIGH severity)                                     │
│     ├─ Re-run Checkov                                                   │
│     └─ Ensure no new vulnerabilities                                    │
│                                                                          │
│  2. 📋 Terraform Plan                                                    │
│     ├─ Plan infrastructure changes                                      │
│     ├─ Plan Vault changes                                               │
│     ├─ Generate detailed plan                                           │
│     └─ Upload plan artifacts (30-day retention)                         │
│                                                                          │
│  3. ⏸️  WAIT FOR SENIOR APPROVAL                                         │
│     ├─ Senior reviewers get notification                                │
│     ├─ Review plan thoroughly                                           │
│     ├─ Wait timer (10 minutes)                                          │
│     ├─ Require 2-3 approvals                                            │
│     └─ Approve or reject                                                │
│                                                                          │
│  4. 🚀 Terraform Apply (After All Approvals)                             │
│     ├─ Log deployment start                                             │
│     ├─ Apply infrastructure                                             │
│     ├─ Apply Vault config                                               │
│     ├─ Capture outputs                                                  │
│     └─ Save outputs (90-day retention)                                  │
│                                                                          │
│  5. 🏥 Comprehensive Health Checks                                       │
│     ├─ Wait 2 minutes for stabilization                                 │
│     ├─ Check EC2 instances                                              │
│     ├─ Check Load Balancers                                             │
│     ├─ Check Target Groups                                              │
│     ├─ Check RDS databases                                              │
│     ├─ Check Auto Scaling Groups                                        │
│     ├─ Check Vault health                                               │
│     ├─ Run smoke tests                                                  │
│     └─ Generate detailed summary                                        │
│                                                                          │
│  6. 📧 Notifications                                                     │
│     ├─ Success: Notify team                                             │
│     ├─ Failure: Alert on-call + rollback plan                           │
│     └─ Log deployment details                                           │
│                                                                          │
│  ✅ PRODUCTION Environment Updated                                       │
└─────────────────────────────────────────────────────────────────────────┘


## 🔐 RBAC (Role-Based Access Control)

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Environments                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  DEV Environment                                             │
│  ├─ No approval required                                     │
│  ├─ Any team member can deploy                              │
│  └─ Auto-deploy on merge                                     │
│                                                              │
│  STAGING Environment                                         │
│  ├─ Requires 1-2 approvals                                   │
│  ├─ Team members can approve                                │
│  ├─ 5-minute wait timer (optional)                           │
│  └─ Branch restriction: staging only                         │
│                                                              │
│  PRODUCTION-PLAN Environment                                 │
│  ├─ Requires 1 approval                                      │
│  ├─ Senior team member can approve                           │
│  └─ Branch restriction: main/prod only                       │
│                                                              │
│  PRODUCTION Environment                                      │
│  ├─ Requires 2-3 senior approvals                            │
│  ├─ 10-minute wait timer                                     │
│  ├─ Prevent self-review enabled                              │
│  ├─ Branch restriction: main/prod only                       │
│  └─ Audit log of all approvals                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 AWS IAM Roles (OIDC)

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS IAM Structure                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  OIDC Provider                                               │
│  └─ token.actions.githubusercontent.com                      │
│                                                              │
│  IAM Roles (One per environment)                             │
│  ├─ GitHubActions-Terraform-Dev                              │
│  │  ├─ Trust: GitHub repo + dev branch                       │
│  │  └─ Policy: AdministratorAccess (or custom)               │
│  │                                                            │
│  ├─ GitHubActions-Terraform-Staging                          │
│  │  ├─ Trust: GitHub repo + staging branch                   │
│  │  └─ Policy: AdministratorAccess (or custom)               │
│  │                                                            │
│  └─ GitHubActions-Terraform-Prod                             │
│     ├─ Trust: GitHub repo + main/prod branch                 │
│     └─ Policy: AdministratorAccess (or custom)               │
│                                                              │
│  Security Features                                           │
│  ├─ No long-lived credentials                                │
│  ├─ Temporary tokens (1 hour)                                │
│  ├─ Repository-specific access                               │
│  └─ Branch-specific access                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Workflow Files

```
.github/workflows/
│
├─ terraform-ci.yml
│  ├─ Runs on: Pull Requests
│  ├─ Purpose: Quality & Security Checks
│  └─ Jobs:
│     ├─ Format Check
│     ├─ Validation
│     ├─ Security Scan (tfsec)
│     ├─ Security Scan (Checkov)
│     ├─ Linting (tflint)
│     └─ Cost Estimation
│
├─ terraform-cd-dev.yml
│  ├─ Runs on: Push to dev
│  ├─ Purpose: Auto-deploy to DEV
│  └─ Jobs:
│     ├─ Plan
│     ├─ Apply (auto)
│     └─ Health Check
│
├─ terraform-cd-staging.yml
│  ├─ Runs on: Push to staging
│  ├─ Purpose: Deploy to STAGING
│  └─ Jobs:
│     ├─ Plan
│     ├─ Apply (manual approval)
│     └─ Health Check
│
└─ terraform-cd-prod.yml
   ├─ Runs on: Push to main/prod
   ├─ Purpose: Deploy to PRODUCTION
   └─ Jobs:
      ├─ Security Re-check
      ├─ Plan (manual approval)
      ├─ Apply (senior approval)
      ├─ Health Check
      └─ Notifications
```

## 🎯 Branch Strategy

```
main (production)
  │
  ├─ Protected branch
  ├─ Requires PR reviews
  ├─ Triggers production deployment
  └─ Merges from: staging
      │
      staging
      │
      ├─ Protected branch
      ├─ Requires PR reviews
      ├─ Triggers staging deployment
      └─ Merges from: dev
          │
          dev
          │
          ├─ Protected branch (optional)
          ├─ Triggers dev deployment
          └─ Merges from: feature branches
              │
              feature/my-feature
              │
              ├─ Created from dev
              ├─ Triggers CI checks on PR
              └─ Deleted after merge
```
