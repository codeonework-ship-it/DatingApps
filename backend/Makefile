SHELL := /bin/bash

.PHONY: proto run-auth run-profile run-matching run-chat run-bff run-gateway run-all stop-all open-docs

# Requires protoc + protoc-gen-go + protoc-gen-go-grpc installed locally.
proto:
	protoc --go_out=. --go-grpc_out=. api/proto/*.proto

run-auth:
	go run ./cmd/auth-svc

run-profile:
	go run ./cmd/profile-svc

run-matching:
	go run ./cmd/matching-svc

run-chat:
	go run ./cmd/chat-svc

run-bff:
	go run ./cmd/mobile-bff

run-gateway:
	go run ./cmd/api-gateway

run-all:
	chmod +x ./scripts/dev_up.sh ./scripts/dev_down.sh
	./scripts/dev_up.sh

stop-all:
	chmod +x ./scripts/dev_down.sh
	./scripts/dev_down.sh

open-docs:
	OPEN_CHROME=true ./scripts/dev_up.sh
