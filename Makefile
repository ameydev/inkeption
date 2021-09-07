IMAGE_NAME= ameydev/inkeption

inkeption-image:
	@docker build -t $(IMAGE_NAME):latest -f Dockerfile .
