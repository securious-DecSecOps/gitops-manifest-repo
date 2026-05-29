# GitOps Manifests — DevSecOps Golden Path

[SecuBank DevSecOps Golden Path](https://securious-decsecops.github.io/secubank-docs/)의 Kubernetes desired state다. **ArgoCD가 이 레포를 watch하여 런타임(k3s)에 선언적으로 동기화**한다(Git = 단일 진실).

## 구조

```
helm/vulnbank-msa/            # VulnBank MSA Helm 차트 (deployment·service·database·db-init)
apps/vulnbank-msa/dev/        # 로컬(kind) 환경 values
apps/vulnbank-msa/aws-dev/    # AWS 환경 values (이미지 레지스트리·태그)
argocd/root/aws-dev.yaml      # app-of-apps 루트 Application
argocd/aws-apps/              # 자식 앱 (vulnbank · cilium-hubble · falco · kube-bench · owasp-zap)
platform/                     # 런타임 보안 플랫폼 매니페스트
  ├─ cilium-hubble/           #   eBPF CNI + Hubble + 제로트러스트 NetworkPolicy
  ├─ falco/                   #   런타임 위협 탐지(+ VulnBank 커스텀 룰, Prometheus 메트릭)
  ├─ kube-bench/              #   CIS 벤치마크 CronJob
  └─ owasp-zap/               #   DAST CronJob
```

## 배포 흐름

ArgoCD가 `argocd/root/aws-dev.yaml`(app-of-apps)을 sync → `argocd/aws-apps/`의 자식 앱들이 생성되어 VulnBank + 보안 플랫폼이 k3s에 배포된다. `syncPolicy.automated`로 드리프트 자동 교정.

## ⚠ 검증 워크로드 — 운영 배포 금지

VulnBank MSA는 의도된 4개 취약점(음수송금·IDOR×2·파일업로드 RCE)을 가진 **lab target**이다. 런타임 보안(Cilium/Falco)이 이를 관측·차단하는 대상이며, 운영 배포 대상이 아니다.

## License

Apache License 2.0 — `LICENSE` 참고.
