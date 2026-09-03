# Architecture Overview

## Purpose

Azure CloudOps is a portfolio environment that demonstrates how a cloud engineer supports an application throughout its lifecycle: deployment, networking, access control, monitoring, governance, automation, cost management, and troubleshooting.

## Logical components

### Application layer

- **Azure Static Web Apps** hosts the public front end.
- **Azure Functions** provides serverless API functionality.
- **Application Insights** records application requests, failures, and performance telemetry.

### Infrastructure layer

- **Terraform** defines repeatable Azure infrastructure.
- **Virtual networks, subnets, and NSGs** demonstrate segmentation and traffic control.
- Network resources will support operational labs without forcing the public static site through unnecessary private networking.

### Operations layer

- **Azure Monitor** collects platform metrics and logs.
- **Alerts** surface availability, application, or infrastructure problems.
- **Budgets** protect the pay-as-you-go subscription from unexpected spending.

### Governance and security

- **RBAC** grants least-privilege administrative access.
- **Azure Policy** checks or enforces configuration standards.
- **Tags** identify environment, owner, workload, and cost purpose.
- Secrets remain in GitHub or Azure secret stores and are never committed.

### Automation layer

- **GitHub Actions** validates and deploys application changes.
- **Terraform** plans and applies reviewed infrastructure changes.
- Azure Static Web Apps will initially generate the application deployment workflow.

## Design principles

1. Keep the public application simple and reliable.
2. Use infrastructure resources only when they demonstrate a clear cloud-engineering skill.
3. Prefer low-cost or free tiers and configure budget alerts early.
4. Keep application deployment separate from infrastructure deployment.
5. Document failures, troubleshooting steps, and improvements as portfolio evidence.

## Planned request flow

1. A visitor opens the Azure Static Web Apps URL.
2. Azure serves the front-end assets.
3. The front end optionally calls an Azure Functions API.
4. Application Insights records telemetry.
5. Azure Monitor evaluates signals and triggers configured alerts.

## Planned CI/CD flow

1. A change is pushed or merged into `main`.
2. GitHub Actions builds and validates the application.
3. The workflow deploys the application to Azure Static Web Apps.
4. Infrastructure changes run through a separate Terraform workflow with validation and plan stages.
