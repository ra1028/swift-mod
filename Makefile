SWIFT_FORMAT_PATHS := Sources $(shell find Tests -type f -name "*.swift")
SWIFT_MOD_PATHS := $(shell find Sources -type f -name "*.swift" -not -path "Sources/swift-mod/*")
SWIFT_BUILD_FLAGS := -c release --disable-sandbox
TOOL_NAME := swift-mod
XCODE_DEFAULT_TOOLCHAIN := /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
GITHUB_REPO := ra1028/$(TOOL_NAME)
DOCKER_IMAGE_NAME := swift:6.1

ifeq ($(shell uname), Darwin)
SWIFT_BUILD_FLAGS += --arch arm64 --arch x86_64
endif

TOOL_BIN_DIR := $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)
TOOL_BIN := $(TOOL_BIN_DIR)/$(TOOL_NAME)

.PHONY: $(MAKECMDGOALS)

build:
	swift build $(SWIFT_BUILD_FLAGS)
	@echo $(TOOL_BIN)

test:
	swift test -c release --parallel

mod:
	swift run -c release swift-mod $(SWIFT_MOD_PATHS)

format:
	swift run -c release --package-path ./Tools -- swift-format format --configuration .swift-format.json -i -r $(SWIFT_FORMAT_PATHS)

lint:
	swift run -c release --package-path ./Tools -- swift-format lint --configuration .swift-format.json -r $(SWIFT_FORMAT_PATHS)

autocorrect: mod format lint

ubuntu-deps:
	apt-get update --assume-yes
	apt-get install --assume-yes libsqlite3-dev libncurses-dev

docker-test:
	docker run -v `pwd`:`pwd` -w `pwd` --rm $(DOCKER_IMAGE_NAME) make ubuntu-deps test

zip: build
	install_name_tool -add_rpath @loader_path -add_rpath $(XCODE_DEFAULT_TOOLCHAIN)/usr/lib/swift/macosx $(TOOL_BIN) 2>/dev/null || true
	rm -f $(TOOL_NAME).zip
	zip -j $(TOOL_NAME).zip $(TOOL_BIN) LICENSE

upload-zip: zip
	@[ -n "$(GITHUB_TOKEN)" ] || (echo "\nERROR: Make sure setting environment variable 'GITHUB_TOKEN'." && exit 1)
	@[ -n "$(GITHUB_RELEASE_ID)" ] || (echo "\nERROR: Make sure setting environment variable 'GITHUB_RELEASE_ID'." && exit 1)
	curl -sSL -X POST \
	  -H "Authorization: token $(GITHUB_TOKEN)" \
	  -H "Content-Type: application/zip" \
	  --upload-file "./$(TOOL_NAME).zip" "https://uploads.github.com/repos/$(GITHUB_REPO)/releases/$(GITHUB_RELEASE_ID)/assets?name=$(TOOL_NAME).zip"
