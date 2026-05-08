# On-Premise / Híbrido (placeholder)

> **Estado:** Para casos donde la regulación, soberanía de datos o latencia obliga a no usar nube pública.

## Cuándo aplica

- Sectores regulados (defensa, salud, banca con normativas de soberanía)
- Latencia ultra-baja con hardware específico (manufactura, trading)
- Costos predecibles muy altos donde cloud no compite a escala
- Estrategia híbrida: core on-prem + bursting a cloud

## Opciones a documentar

- [ ] `01-vmware-tanzu.md` — modernización a contenedores en VMware
- [ ] `02-openshift.md` — Red Hat OpenShift on-prem
- [ ] `03-rancher-k3s.md` — Kubernetes ligero on-prem
- [ ] `04-azure-stack-hci.md` — Azure Stack HCI / Hub / Edge
- [ ] `05-aws-outposts.md` — AWS Outposts
- [ ] `06-google-distributed-cloud.md` — GDC Hosted / Edge

## Patrones híbridos comunes

- **Private connectivity**: ExpressRoute / Direct Connect / Cloud Interconnect
- **Identity bridge**: AD on-prem federado con Entra ID / Cognito / GCP IAM
- **Data gravity**: BD on-prem, compute cloud para batch / IA
- **Backup off-site**: cloud como destino de respaldo y DR

## Consideraciones

- Costos de hardware + licencias + operación frecuentemente subestimados
- Curva operativa alta — equipo on-call 24/7 con conocimiento profundo
- Refresh de hardware cada 3-5 años con CAPEX significativo
- Dificultad de retener talento que prefiere stacks cloud-native
