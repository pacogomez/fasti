BINARY=fasti
BUILD_FLAGS=
DEBUG_PREFIX=.build/debug
RELEASE_PREFIX=.build/release
INSTALL_PREFIX=~/bin

debug:
	swift build $(BUILD_FLAG)

release: clean
	swift build $(BUILD_FLAGS) --configuration release

install: release uninstall
	cp $(RELEASE_PREFIX)/$(BINARY) $(INSTALL_PREFIX)/$(BINARY)

uninstall:
	rm -f $(INSTALL_PREFIX)/$(BINARY)

run: debug
	$(DEBUG_PREFIX)/$(BINARY)

clean:
	swift package clean
	rm -rf .build
