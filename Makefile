GOFMT_FILES?=$$(find . -name '*.go' | grep -v vendor)
GOFMT := "goimports"

depend:
	@go get -v \
	golang.org/x/lint/golint \
	github.com/golangci/golangci-lint/cmd/golangci-lint \
	golang.org/x/tools/cmd/goimports \
	gopkg.in/src-d/go-kallax.v1/... \
	github.com/gogo/protobuf/protoc-gen-gogo \
	github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
	github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger \
	github.com/mwitkow/go-proto-validators/protoc-gen-govalidators \
	github.com/go-bindata/go-bindata/...

dep: ## Manage dependencies
	dep ensure -add github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger github.com/gogo/googleapis/google/api github.com/gogo/protobuf/gogoproto github.com/grpc-ecosystem/go-grpc-middleware/validator github.com/mwitkow/go-proto-validators/protoc-gen-govalidators go.opencensus.io/trace contrib.go.opencensus.io/exporter/stackdriver gopkg.in/src-d/go-kallax.v1 github.com/grpc-ecosystem/go-grpc-prometheus github.com/grpc-ecosystem/go-grpc-middleware git.begroup.team/platform-core/kitchen google.golang.org/grpc/reflection google.golang.org/grpc/metadata

fmt: ## Run gofmt for all .go files
	@$(GOFMT) -w $(GOFMT_FILES)

generate: ## Generate proto
	protoc \
		-I proto/ \
		-I vendor/github.com/grpc-ecosystem/grpc-gateway/ \
		-I vendor/github.com/gogo/googleapis/ \
		-I vendor/ \
		--descriptor_set_out=./descriptors.protoset\
		--include_source_info --include_imports -I. \
		--gogo_out=plugins=grpc,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/api/annotations.proto=github.com/gogo/googleapis/google/api,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types:\
pb \
		--grpc-gateway_out=\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/api/annotations.proto=github.com/gogo/googleapis/google/api,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types:\
pb \
		--swagger_out=docs \
		--govalidators_out=gogoimport=true,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/api/annotations.proto=github.com/gogo/googleapis/google/api,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types:\
pb \
		proto/*.proto

test: ## Run go test for whole project
	@go test -v ./...

lint: ## Run linter
	@golangci-lint run ./...

help: ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
