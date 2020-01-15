SWIFT_FORMAT_PATHS := Sources/ $(shell find Tests/**/*.swift -not -name XCTestManifests.swift -not -name LinuxMain.swift)
SWIFT_BUILD_FLAGS := -c release --disable-sandbox
TOOL_NAME := swift-mod
TOOL_BIN_DIR := $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/$(TOOL_NAME)
XCODE_DEFAULT_TOOLCHAIN := /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
GITHUB_REPO := ra1028/$(TOOL_NAME)

ifeq ($(shell uname), Darwin)
USE_SWIFT_STATIC_STDLIB := $(shell test -d $$(dirname $$(xcrun --find swift))/../lib/swift_static/macosx && echo use_swift_static_stdlib_flag)
ifeq ($(USE_SWIFT_STATIC_STDLIB), use_swift_static_stdlib_flag)
SWIFT_BUILD_FLAGS += -Xswiftc -static-stdlib
endif
endif

.PHONY: $(MAKECMDGOALS)

xcodeproj:
	swift package generate-xcodeproj

linuxmain:
	swift test -c release --generate-linuxmain

build:
	swift build $(SWIFT_BUILD_FLAGS)
	@echo $(TOOL_BIN_DIR)/$(TOOL_NAME)

test:
	swift test -c release --parallel

mod:
	swift run -c release swift-mod

format:
	swift run -c release --package-path ./Packages swift-format --configuration .swift-format.json -i -r -m format $(SWIFT_FORMAT_PATHS)

lint:
	swift run -c release --package-path ./Packages swift-format --configuration .swift-format.json -r -m lint $(SWIFT_FORMAT_PATHS)

autocorrect: mod format lint linuxmain

pod-lib-lint:
	bundle exec pod lib lint

pod-trunk-push:
	bundle exec pod trunk push --skip-tests --skip-import-validation swift-mod.podspec

docker-test:
	docker run -v `pwd`:`pwd` -w `pwd` --rm swift:latest make test

docker-pull:
	docker pull swift:latest

gem-install:
	bundle config path vendor/bundle
	bundle install --jobs 4 --retry 3

zip: build
	@install_name_tool -add_rpath $(XCODE_DEFAULT_TOOLCHAIN)/usr/lib/swift/macosx $(TOOL_BIN_DIR) 2>/dev/null || true
	rm -f $(TOOL_NAME).zip
	zip -j $(TOOL_NAME).zip $(TOOL_BIN_DIR) LICENSE

upload-zip: zip
	@[ -n "$(GITHUB_TOKEN)" ] || (echo "\nERROR: Make sure setting environment variable 'GITHUB_TOKEN'." && exit 1)
	@[ -n "$(GITHUB_RELEASE_ID)" ] || (echo "\nERROR: Make sure setting environment variable 'GITHUB_RELEASE_ID'." && exit 1)
	curl -sSL -X POST \
	  -H "Authorization: token $(GITHUB_TOKEN)" \
	  -H "Content-Type: application/zip" \
	  --upload-file "./$(TOOL_NAME).zip" "https://uploads.github.com/repos/$(GITHUB_REPO)/releases/$(GITHUB_RELEASE_ID)/assets?name=$(TOOL_NAME).zip"
