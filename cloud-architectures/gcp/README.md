# GCP — Cloud Architectures (placeholder)

> **Estado:** Pendiente de poblar.

- [ ] `01-iaas-lift-and-shift.md` — Compute Engine, VPC, Cloud Storage, Cloud Load Balancing
- [ ] `02-paas-app-engine-cloud-run.md` — App Engine Standard/Flex, Cloud Run, Cloud SQL, Memorystore
- [ ] `03-containers-gke.md` — GKE Autopilot / Standard, Artifact Registry
- [ ] `04-serverless-cloud-functions.md` — Cloud Functions, Cloud Run jobs, Eventarc, Pub/Sub
- [ ] `05-microservices-event-driven.md` — Cloud Run + Pub/Sub + Eventarc + Workflows

## Equivalencias rápidas Azure ↔ GCP

| Azure | GCP |
| --- | --- |
| App Service | App Engine / Cloud Run |
| Container Apps | Cloud Run |
| Functions | Cloud Functions (2nd gen) |
| AKS | GKE (Autopilot recomendado) |
| Service Bus / Event Grid | Pub/Sub + Eventarc |
| Event Hubs | Pub/Sub Lite o Pub/Sub estándar |
| Cosmos DB | Firestore / Bigtable |
| Azure SQL | Cloud SQL / Spanner |
| Key Vault | Secret Manager |
| Application Insights | Cloud Logging + Cloud Trace + Cloud Monitoring |
| Entra ID | Cloud Identity + IAM |

## IaC sugerido

- **Terraform** (estándar de facto en GCP)
- **Deployment Manager** (legacy, no recomendado para nuevos proyectos)
- **Config Connector** (Kubernetes-native IaC)
