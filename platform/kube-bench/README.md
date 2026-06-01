# 🛡️ kube-bench CIS Kubernetes Benchmark Agent

본 에이전트는 **aquasecurity/kube-bench**를 활용하여 Kubernetes 클러스터가 CIS(Center for Internet Security) Kubernetes Benchmark의 보안 권장 사항을 준수하고 있는지 주기적 및 능동적으로 감사하는 보안 진단 에이전트입니다.

K3s 환경에 완벽히 최적화되어 마스터/워커 노드의 보안 설정 미흡 사항(Misconfiguration)을 탐지하고 분석 보고서를 생성합니다.

---

## 🛠️ 주요 특징 & 설계 구조

1. **K3s 최적화**: K3s의 경량 싱글 바이너리 아키텍처 특성에 맞추어 `--benchmark k3s-cis-1.7` 프로파일을 활용해 불필요한 마스터 파일 검사 경고(False Positives)를 줄이고 실질적인 보안 점검을 제공합니다.
2. **주기적 스캔 (CronJob)**: `schedule: "0 3 * * 1"` 설정을 통해 매주 월요일 새벽 3시에 백그라운드에서 보안 감사를 자동 수행합니다.
3. **호스트 리소스 접근 및 격리 해제**: 노드 내부 설정값(e.g., Kubelet 아규먼트, OS 설정 파일 등)을 검사할 수 있도록 `hostPID: true`, `privileged: true` 및 볼륨 마운트(`/var/lib/rancher`, `/var/lib/kubelet`, `/etc/systemd`)를 설정하였습니다.
4. **보안 최소 권한 (RBAC)**: K8s 자원에 조회가 필요한 경우를 대비해 `nodes` 및 `pods`에 대해서만 `get`, `list` 권한을 갖는 `ServiceAccount`를 매핑했습니다.
5. **DefectDojo 업로드 분리**: `kube-bench` 컨테이너는 JSON 리포트 생성만 담당하고, `defectdojo-upload` 컨테이너가 같은 `emptyDir` 볼륨의 리포트를 DefectDojo `kube-bench Scan` parser로 업로드합니다.

---

## 📂 파일 구조

* `namespace.yaml`: `kube-bench` 전용 네임스페이스 정의
* `rbac.yaml`: 노드 및 파드 메타데이터 조회 목적의 최소 권한 RBAC 정책
* `cronjob.yaml`: 매주 월요일 새벽 3시에 작동하는 K3s 대응 kube-bench 스캔 CronJob
* `README.md`: 본 문서

---

## 🚀 사용법 및 트러블슈팅

### 1) 수동 스캔 즉시 트리거 (One-off Job)
배포 이후 Jenkins 파이프라인 연동 전 또는 테스트 목적으로 즉시 진단을 시작하려면, CronJob을 기반으로 임시 Job을 생성하여 수행할 수 있습니다.

```bash
kubectl create job kube-bench-manual-$(date +%Y%m%d%H%M%S) \
  --from=cronjob/kube-bench \
  -n kube-bench
```

### 2) DefectDojo 업로드 토큰 준비

kube-bench CronJob은 스캔 결과를 JSON으로 생성한 뒤 DefectDojo의 `kube-bench Scan` parser로 업로드합니다.
업로드는 `curlimages/curl` 기반 `defectdojo-upload` 컨테이너가 담당합니다.
DefectDojo API 토큰은 GitOps 매니페스트에 평문으로 저장하지 않고, 런타임 클러스터의 Secret으로 주입합니다.

```bash
kubectl create secret generic defectdojo-api-token \
  -n kube-bench \
  --from-literal=token='<DefectDojo Token>'
```

### 3) 스캔 결과 로그 확인
진단이 완료되면 아래 명령어로 생성된 Pod의 로그를 조회하여 각 CIS 평가 항목의 통과(`[PASS]`), 실패(`[FAIL]`), 경고(`[WARN]`) 내역을 확인합니다.

```bash
# 실행 중이거나 완료된 파드 조회
kubectl get pods -n kube-bench

# 진단 보고서(로그) 출력
kubectl logs -n kube-bench -l app.kubernetes.io/name=kube-bench --tail=500
```

DefectDojo 업로드가 성공하면 로그에 `DefectDojo upload success`가 출력되고, DefectDojo Engagement에 kube-bench Test가 생성됩니다.

### 4) 실패 항목 조치 가이드 (Remediation)
로그의 최하단에 각 실패 코드(`[FAIL]`)에 맞는 상세 Remediation Guide가 동적 출력됩니다.
K3s 환경에서의 설정 변경은 다음 가이드를 따르십시오.

* **K3s 설정 변경**: `/etc/rancher/k3s/config.yaml`에 CIS Harden 옵션을 반영한 뒤 K3s 서비스를 재시작합니다.
  ```yaml
  # 예시 (/etc/rancher/k3s/config.yaml)
  protect-kernel-defaults: true
  secrets-encryption: true
  ```
  ```bash
  sudo systemctl restart k3s
  ```
