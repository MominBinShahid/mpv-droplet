# Builds /Applications/mpv.app from mpv-droplet.applescript, with the mpv logo as its icon.
# make only redoes the steps whose inputs changed (see README.md).

APP     := /Applications/mpv.app
STAGED  := build/mpv.app
SCRIPT  := mpv-droplet.applescript
# Homebrew's prefix: /opt/homebrew on Apple Silicon, /usr/local on Intel (empty if brew is missing)
BREW    := $(shell brew --prefix 2>/dev/null)
SVG     := $(BREW)/opt/mpv/share/icons/hicolor/scalable/apps/mpv.svg
ICONSET := build/mpv.iconset
ICNS    := build/mpv.icns
SIZES   := 16 32 128 256 512
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

.PHONY: build icon open check clean uninstall

build: $(APP)

icon: $(ICNS)

# Installs the staged app only after it compiled and signed cleanly,
# so a compile error never deletes the working app.
$(APP): $(STAGED)
	rm -rf "$@"
	ditto "$(STAGED)" "$@"
	touch "$@"
	$(LSREGISTER) -f "$@"
	@echo "Built $@"

# The app is rebuilt when the script or the icon changes.
$(STAGED): $(SCRIPT) $(ICNS)
	rm -rf "$@"
	osacompile -o "$@" $(SCRIPT)
	cp $(ICNS) "$@/Contents/Resources/droplet.icns"
	rm -f "$@/Contents/Resources/Assets.car"
	-/usr/libexec/PlistBuddy -c 'Delete :CFBundleIconName' "$@/Contents/Info.plist" 2>/dev/null
	codesign --force --deep --sign - "$@"
	touch "$@"

# The icon is rebuilt only when mpv's logo or the render helper changes.
$(ICNS): $(SVG) svg2png.swift
	rm -rf $(ICONSET) && mkdir -p $(ICONSET)
	for s in $(SIZES); do \
	  swift svg2png.swift $(SVG) $(ICONSET)/icon_$${s}x$${s}.png $$s && \
	  swift svg2png.swift $(SVG) $(ICONSET)/icon_$${s}x$${s}@2x.png $$((s * 2)) || exit 1; \
	done
	iconutil -c icns $(ICONSET) -o $@

# Only runs when mpv's logo is missing, i.e. Homebrew or mpv isn't installed.
$(SVG):
	@if [ -z "$(BREW)" ]; then echo "Homebrew not found; install it from https://brew.sh, then run: brew install mpv" >&2; \
	else echo "mpv not found; run: brew install mpv" >&2; fi
	@exit 1

open: $(APP)
	open "$(APP)"

check:
	codesign --verify --verbose "$(APP)"
	plutil -p "$(APP)/Contents/Info.plist" | grep -A6 CFBundleDocumentTypes

clean:
	rm -rf build

uninstall:
	rm -rf "$(APP)"
