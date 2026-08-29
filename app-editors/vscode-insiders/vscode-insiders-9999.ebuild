# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="af am ar bg bn ca cs da de el en-GB es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk ur vi zh-CN zh-TW"

inherit chromium-2 desktop optfeature pax-utils shell-completion xdg

DESCRIPTION="Multiplatform Visual Studio Code - Insiders from Microsoft"
HOMEPAGE="https://code.visualstudio.com/insiders"
SRC_URI="
	amd64? ( https://update.code.visualstudio.com/latest/linux-x64/insider -> ${P}-amd64.tar.gz )
	arm? ( https://update.code.visualstudio.com/latest/linux-armhf/insider -> ${P}-arm.tar.gz )
	arm64? ( https://update.code.visualstudio.com/latest/linux-arm64/insider -> ${P}-arm64.tar.gz )
"
S="${WORKDIR}"

LICENSE="
	Apache-2.0
	BSD
	BSD-1
	BSD-2
	BSD-4
	CC-BY-4.0
	ISC
	LGPL-2.1+
	Microsoft-vscode
	MIT
	MPL-2.0
	openssl
	PYTHON
	TextMate-bundle
	Unlicense
	UoI-NCSA
	W3C
"
SLOT="0"
IUSE="egl wayland webkit"
RESTRICT="mirror strip bindist"

RDEPEND="
	|| (
		sys-apps/systemd
		sys-apps/systemd-utils
	)
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret[crypt]
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/mesa
	net-misc/curl
	sys-apps/dbus
	virtual/zlib:=
	sys-process/lsof
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libxkbfile
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/pango
	x11-misc/xdg-utils
	webkit? (
		net-libs/libsoup:3.0
		net-libs/webkit-gtk:4.1
	)
"

QA_PREBUILT="*"

src_unpack() {
	default
	mv "${S}"/VSCode-linux-* "${S}/vscode" || die
}

src_configure() {
	default
	chromium_suid_sandbox_check_kernel_config
}

src_prepare() {
	default
	pushd "vscode/locales" > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die
}

src_install() {
	cd vscode || die

	# Disable update server
	sed -e "/updateUrl/d" -i ./resources/app/product.json || die

	if ! use webkit; then
		rm -r ./resources/app/extensions/microsoft-authentication || die
	fi

	# Install
	pax-mark m code-insiders
	mkdir -p "${ED}/opt/${PN}" || die
	cp -r . "${ED}/opt/${PN}" || die
	fperms 4711 /opt/${PN}/chrome-sandbox

	dosym -r "/opt/${PN}/bin/code-insiders" "usr/bin/vscode-insiders"
	dosym -r "/opt/${PN}/bin/code-insiders" "usr/bin/code-insiders"

	local EXEC_EXTRA_FLAGS=()
	if use wayland; then
		EXEC_EXTRA_FLAGS+=( "--ozone-platform-hint=auto" "--enable-wayland-ime" )
	fi
	if use egl; then
		EXEC_EXTRA_FLAGS+=( "--use-gl=egl" )
	fi

	sed "s|@exec_extra_flags@|${EXEC_EXTRA_FLAGS[*]}|g" \
		"${FILESDIR}/code-insiders-url-handler.desktop" \
		> "${T}/code-insiders-url-handler.desktop" || die

	sed "s|@exec_extra_flags@|${EXEC_EXTRA_FLAGS[*]}|g" \
		"${FILESDIR}/code-insiders.desktop" \
		> "${T}/code-insiders.desktop" || die

	domenu "${T}/code-insiders.desktop"
	domenu "${T}/code-insiders-url-handler.desktop"
	newicon "resources/app/resources/linux/code.png" "vscode-insiders.png"

	# Install metainfo
	insinto /usr/share/metainfo
	doins "${FILESDIR}/code-insiders.appdata.xml"

	# Install MIME type definitions
	insinto /usr/share/mime/packages
	doins "${FILESDIR}/code-insiders-workspace.xml"

	# Install completions
	newbashcomp resources/completions/bash/code-insiders code-insiders
	newzshcomp resources/completions/zsh/_code-insiders _code-insiders
}

pkg_postinst() {
	xdg_pkg_postinst
	optfeature "desktop notifications" x11-libs/libnotify
	optfeature "keyring support inside vscode" "virtual/secret-service"
	optfeature "Live Share" dev-libs/icu
}
