# 🌐 Cilium CNI & Hubble 관측성 에이전트

eBPF 기반의 차세대 CNI로 K3s 기본 Flannel을 완전히 대체하고, L3-L7 제로트러스트 네트워크 보안 정책과 Hubble UI 실시간 네트워크 플로우 시각화를 제공합니다.

---

## 🏗️ 아키텍처 개요

```
[외부 클라이언트]
      │ TCP 8080
      ▼
[Frontend Pod]  ──L7 HTTP GET/POST /api.php──▶  [user-service]
                                                  [transaction-service]
                                                  [status-service]      ──TCP 3306──▶  [vulnbank-db]
                                                  [file-service]
                                                  [settings-service]

모든 Pod ──UDP/TCP 53──▶ [kube-dns] (DNS 허용)
그 외 모든 트래픽 → ❌ Default Deny (Zero-Trust)
```

---

## 🔑 전제 조건: K3s 설치 시 Flannel CNI 반드시 비활성화

> **⚠️ 중요**: Cilium은 클러스터에 단 하나의 CNI만 허용되므로, K3s 설치 시 기본 Flannel CNI를 사전에 제거해야 합니다.

```bash
# K3s 런타임 서버 설치 명령어 (AWS User-data 스크립트에 반영)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="\
  --flannel-backend=none \
  --disable-network-policy \
  --disable=traefik" sh -
```

| 옵션 | 설명 |
|:---|:---|
| `--flannel-backend=none` | K3s 기본 Flannel CNI 비활성화 |
| `--disable-network-policy` | K3s 내장 NetworkPolicy 컨트롤러 비활성화 (Cilium이 대신 처리) |
| `--disable=traefik` | 기본 IngressController 비활성화 (선택 사항) |

---

## 🚀 배포 방법 (ArgoCD GitOps)

이 도구는 ArgoCD가 `argocd/applications/cilium.yaml`을 감지하여 자동 배포합니다.

```bash
# ArgoCD Application 수동 등록 (최초 1회)
kubectl apply -f argocd/applications/cilium.yaml

# 배포 상태 확인
kubectl get pods -n kube-system -l app.kubernetes.io/part-of=cilium
```

---

## ✅ 동작 상태 확인 방법

### 1. Cilium 에이전트 상태 점검

```bash
# Cilium CLI 설치 (최초 1회)
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --remote-name https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz
tar xzvf cilium-linux-amd64.tar.gz
sudo mv cilium /usr/local/bin

# Cilium 전체 상태 확인 (모든 노드에서 DaemonSet이 정상인지 확인)
cilium status

# 네트워크 연결성 테스트 (Pod-to-Pod 통신 검증)
cilium connectivity test
```

### 2. Hubble 관측성 에이전트 상태 점검

```bash
# Hubble Relay 및 UI 포드 상태 확인
kubectl get pods -n kube-system -l app.kubernetes.io/name=hubble-ui
kubectl get pods -n kube-system -l app.kubernetes.io/name=hubble-relay

# Hubble CLI 상태 확인
hubble status

# 실시간 L7 HTTP 플로우 스트리밍 (secure-path-dev 네임스페이스 필터)
hubble observe --namespace secure-path-dev --type l7 --follow
```

### 3. Hubble UI 접속

운영 기본 방식은 Public NodePort가 아니라 SSM + kubectl port-forward입니다.

Runtime EC2:

```bash
kubectl -n kube-system port-forward svc/hubble-ui 12000:80 --address 127.0.0.1
```

Local PowerShell:

```powershell
aws ssm start-session `
  --profile devsecops `
  --region ap-northeast-2 `
  --target i-05d583e02dcb52aef `
  --document-name AWS-StartPortForwardingSessionToRemoteHost `
  --parameters "host=127.0.0.1,portNumber=12000,localPortNumber=12000"
```

브라우저 접속:

```text
http://localhost:12000/?namespace=secure-path-dev
```

Hubble UI는 service map과 topology 확인용입니다. Cilium에서 dropped 처리한 상세 flow와 drop reason은 아래 CLI를 주 증적으로 확인합니다.

```bash
kubectl -n kube-system exec ds/cilium -- hubble observe --namespace secure-path-dev --verdict DROPPED --last 100
kubectl -n kube-system exec ds/cilium -- hubble observe --namespace secure-path-dev --verdict DROPPED --last 100 -o json
```

---

## 🛡️ 네트워크 정책 확인 및 트러블슈팅

### 적용된 정책 목록 확인

```bash
# secure-path-dev 내의 모든 CiliumNetworkPolicy 조회
kubectl get cnp -n secure-path-dev

# 특정 정책의 상세 내용 확인
kubectl describe cnp allow-frontend-to-backends -n secure-path-dev
```

### 정책 적용 효과 검증 (격리 확인)

```bash
# ✅ [허용 테스트] Frontend에서 user-service API 호출 (정상 통신 확인)
kubectl exec -n secure-path-dev deploy/frontend -- \
  curl -s http://vulnbank-msa-user-service:8080/api.php

# ❌ [차단 테스트] Backend에서 외부 인터넷 통신 시도 (Default Deny에 의해 차단되어야 함)
kubectl exec -n secure-path-dev deploy/user-service -- \
  curl --connect-timeout 3 -s https://github.com
# 결과: 타임아웃 → 정상 차단 확인

# ❌ [차단 테스트] Frontend에서 DB 포트 직접 접근 시도 (차단되어야 함)
kubectl exec -n secure-path-dev deploy/frontend -- \
  curl --connect-timeout 3 -s http://vulnbank-db:3306
# 결과: 타임아웃 → 정상 차단 확인
```

### Hubble로 차단된 트래픽 실시간 추적

```bash
# 드랍된(차단된) 트래픽만 필터링하여 확인 (보안 이벤트 모니터링)
hubble observe --namespace secure-path-dev --verdict DROPPED --follow

# L7 레이어에서 정상 허용된 HTTP 트래픽 확인
hubble observe --namespace secure-path-dev --verdict FORWARDED --type l7 --follow
```

---

## 📁 파일 구조

```
platform/cilium-hubble/
├── values.yaml                          # Cilium Helm Values (K3s 최적화 설정)
├── hubble-ui-nodeport.yaml              # Hubble UI 임시 NodePort 서비스 (운영 기본은 SSM port-forward)
├── network-policies/
│   ├── default-deny.yaml                # Zero-Trust: 기본 전체 차단 정책
│   └── allow-vulnbank.yaml              # VulnBank MSA 화이트리스트 정책 (6개)
└── README.md                            # 이 파일
```

---

## 🔗 참고 문서

- [Cilium 공식 문서](https://docs.cilium.io/en/stable/)
- [Hubble 공식 문서](https://docs.cilium.io/en/stable/observability/hubble/)
- [Cilium K3s 가이드](https://docs.cilium.io/en/stable/installation/k3s/)
- [CiliumNetworkPolicy API 레퍼런스](https://docs.cilium.io/en/stable/network/kubernetes/policy/)
