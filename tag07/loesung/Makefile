# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION ?= 3.14.0
# renovate: datasource=github-releases depName=golangci/golangci-lint
GOLANGCI_LINT_VERSION ?= v1.55.2

bin/helm:
	mkdir -p bin
	curl -fsSL https://get.helm.sh/helm-v$(HELM_VERSION)-linux-amd64.tar.gz \
	  | tar -xz -C bin --strip-components=1 linux-amd64/helm

lint:
	go run github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION) run
