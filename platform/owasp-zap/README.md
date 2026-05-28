# 🛡️ OWASP ZAP DAST Vulnerability Scanner Agent

이 에이전트는 K3s 클러스터 내부에 배포된 VulnBank MSA Frontend를 대상으로 주기적이고 선언적인 동적 애플리케이션 보안 테스트(DAST, Dynamic Application Security Testing)를 실행합니다.

---

## 1. 주요 특징 및 설계 핵심
* **최소 권한 제로트러스트**: Kubernetes API 자원에 접근하지 않도록 전용 `ServiceAccount`를 비활성화(`automountServiceAccountToken: false`)하여 실행합니다.
* **PSA Restricted 준수**: Pod Security Standards의 `restricted` 프로파일을 완벽하게 충족하며, `readOnlyRootFilesystem: true`, `runAsNonRoot: true` 등으로 안전하게 보호됩니다.
* **보고서 추출 효율성**: 별도의 Persistent Volume(PV) 마운트 없이, `emptyDir` 볼륨에서 생성된 HTML 리포트를 stdout으로 스트리밍하여 `kubectl logs`만으로도 즉각적인 리포트 회수가 가능합니다.

---

## 2. 수동 및 일회성 진단 실행 (Ad-hoc Scan)

예정된 매일 새벽 2시 스케줄링 외에, 배포 직후 즉각적인 취약점 분석을 원할 때 아래 명령어로 일회성 스캔을 유발할 수 있습니다.

```bash
# 1. CronJob 템플릿을 기반으로 일회성 Job 생성
kubectl create job --from=cronjob/owasp-zap owasp-zap-manual -n owasp-zap

# 2. 실행중인 Pod 진행 상황 모니터링 (실시간 터미널 출력)
kubectl logs -f -l job-name=owasp-zap-manual -n owasp-zap

# 3. 진단 완료 후 HTML 리포트만 로컬 파일로 추출하기
kubectl logs job/owasp-zap-manual -n owasp-zap | grep -A 10000 "=== OWASP ZAP REPORT START ===" | grep -v "=== OWASP ZAP REPORT" > zap-dast-report.html
```

---

## 3. 예외 설정 및 튜닝 (ConfigMap)
웹 애플리케이션의 비즈니스 논리에 따라 불필요하게 발생하는 경고(False Positive)는 `configmap.yaml`에 정의된 `zap-baseline.conf` 규칙을 통해 조정할 수 있습니다.

```yaml
# 예시: 특정 Plugin ID 취약점을 무시(IGNORE)하도록 설정
10096   IGNORE   Timestamp Disclosure - Unix
```
수정 후 Git에 커밋하면 ArgoCD가 이를 감지하여 실시간 동기화(Sync)를 수행하고 다음 주기 스캔에 즉시 적용합니다.
