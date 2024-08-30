NAME = boinc-client

.PHONY: build pull release

build:
	docker build --progress=plain -t $(NAME):build .

pull:
	docker build --pull .

test:
	docker build --progress=plain --no-cache-filter=build --target=test . --build-arg BOINC_REPO=
	docker build --progress=plain --no-cache-filter=build --target=test . --build-arg BOINC_REPO=alpha
	docker build --progress=plain --no-cache-filter=build --target=test . --build-arg BOINC_REPO=stable

release:
	docker build --pull -t $(NAME):latest .

fireup:
	docker build --progress=plain -t $(NAME):build .
	docker run --rm -d $(NAME):build
