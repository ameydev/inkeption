IMAGE_NAME= ameydev/k8s-in-pod

k8s-in-pod-image:
	@docker build -t $(IMAGE_NAME):latest -f Dockerfile .
