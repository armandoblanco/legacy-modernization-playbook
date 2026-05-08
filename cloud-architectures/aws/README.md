# AWS — Cloud Architectures (placeholder)

> **Estado:** Pendiente de poblar. Los cinco patrones espejo de `azure/` deben crearse:

- [ ] `01-iaas-lift-and-shift.md` — EC2, VPC, EBS, ALB, CloudFront, ASG, Route 53
- [ ] `02-paas-elastic-beanstalk-app-runner.md` — Elastic Beanstalk, App Runner, RDS, ElastiCache
- [ ] `03-containers-eks.md` — EKS, ECR, ALB Ingress, Karpenter, Fargate
- [ ] `04-serverless-lambda.md` — Lambda, API Gateway, EventBridge, SQS, SNS, DynamoDB
- [ ] `05-microservices-event-driven.md` — ECS Fargate, EventBridge, MSK (Kafka), Step Functions

## Equivalencias rápidas Azure ↔ AWS

| Azure | AWS |
| --- | --- |
| App Service | Elastic Beanstalk / App Runner |
| Container Apps | ECS Fargate / App Runner |
| Functions | Lambda |
| AKS | EKS |
| Service Bus | SQS + SNS |
| Event Grid | EventBridge |
| Event Hubs | Kinesis Data Streams / MSK |
| Cosmos DB | DynamoDB |
| Azure SQL | RDS / Aurora |
| Key Vault | Secrets Manager / Parameter Store |
| Application Insights | CloudWatch + X-Ray |
| Front Door | CloudFront + Global Accelerator |
| Entra ID | IAM + Cognito |
| Bicep | CloudFormation |
| ARM Templates | CloudFormation |

## IaC sugerido

- **Terraform** (recomendado para AWS por madurez)
- **CDK** (TypeScript / Python / .NET)
- **CloudFormation** (nativo, verboso)
- **Pulumi** (multi-cloud)

## AWS Well-Architected Framework

Aplicar los 6 pilares: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability.
