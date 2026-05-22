# gitops-manifest-repo

ArgoCD가 watch하는 Kubernetes desired state.

## 구조

- `helm/vulnbank-msa/` — VulnBank MSA Helm chart (Phase 1~5 산출)
- `helm/simple-web/` — 단일 워크로드 reference chart
- `apps/vulnbank-msa/dev/` — VulnBank MSA dev 환경 overlay (Kustomize + Helm)
- `apps/simple-web/dev/` — simple-web dev overlay (legacy reference)
- `argocd/applications/` — ArgoCD Application 정의
- `k8s/` — 기본 매니페스트 (simple-web용)

## 의도된 vulnerability

이 chart가 배포하는 VulnBank MSA는 **lab workload**다. 의도된 4가지 취약점이 살아있다.
운영 환경 배포 금지.
