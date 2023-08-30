.DEFAULT_GOAL := lint

SWIFT_IMAGE=swift:5.7.1
SWIFTLINT_IMAGE=ghcr.io/realm/swiftlint:0.50.0

lint:
	docker run  --rm -v `pwd`:`pwd` -w `pwd` $(SWIFTLINT_IMAGE) swiftlint lint --strict

lintfix:
	docker run -it --rm -v `pwd`:`pwd` -w `pwd` $(SWIFTLINT_IMAGE) swiftlint --autocorrect

test:
	swift test --filter tinys3Tests

linux_build:
	docker run --rm -v `pwd`:`pwd` -w `pwd` $(SWIFT_IMAGE) swift build -v

linux_test:
	docker run --rm -v `pwd`:`pwd` -w `pwd` $(SWIFT_IMAGE) swift test --filter tinys3Tests

php_test:
	docker run -it --rm -v $(shell pwd)/Tests/php-sample-tests:/app -w /app php:latest php test.php

js_test:
	docker run -it --rm -v $(shell pwd)/Tests/js-sample-tests:/app -w /app node:latest yarn test

start_minio:
	docker run -it --rm -v $(shell pwd)/Tests/e2eTests/minio-local:/data -p 9000:9000 -p 39919:39919 minio/minio:latest server /data --console-address :39919
