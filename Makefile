OS ?= $(shell go env GOOS)
ARCH ?= $(shell go env GOARCH)

PROVIDER := "variomedia"
IMAGE_NAME := "${REGISTRY}cert-manager-webhook-${PROVIDER}"
IMAGE_TAG := "v2.0.1"

OUT := $(shell pwd)/_out

KUBE_VERSION=1.21.2

$(shell mkdir -p "$(OUT)")
export TEST_ASSET_ETCD=_test/kubebuilder/bin/etcd
export TEST_ASSET_KUBE_APISERVER=_test/kubebuilder/bin/kube-apiserver
export TEST_ASSET_KUBECTL=_test/kubebuilder/bin/kubectl

test: _test/kubebuilder
	go test -v .

_test/kubebuilder:
	curl -fsSL https://go.kubebuilder.io/test-tools/$(KUBE_VERSION)/$(OS)/$(ARCH) -o kubebuilder-tools.tar.gz
	mkdir -p _test/kubebuilder
	tar -xvf kubebuilder-tools.tar.gz
	mv kubebuilder/bin _test/kubebuilder/
	rm kubebuilder-tools.tar.gz
	rm -R kubebuilder

clean: clean-kubebuilder

clean-kubebuilder:
	rm -Rf _test/kubebuilder

build:	test
	docker build -t "$(IMAGE_NAME):$(IMAGE_TAG)" .

push:	build
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: rendered-manifest.yaml
rendered-manifest.yaml:
	helm template \
	    --name cert-manager-webhook-${PROVIDER} \
	    --set image.repository=$(IMAGE_NAME) \
	    --set image.tag=$(IMAGE_TAG) \
	    deploy/cert-manager-webhook-${PROVIDER} > "$(OUT)/rendered-manifest.yaml"
