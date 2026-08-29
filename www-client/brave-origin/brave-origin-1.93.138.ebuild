# Copyright 2011-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="af am ar az bg bn ca cs da de el en-GB en-US es-419 es et fa fi fil fr
	gu he hi hr hu id it ja ka kk km kn ko lo lt lv mk ml mn mr ms my nb nl pl pt-BR
	pt-PT ro ru si sk sl sq sr-Latn sr sv sw ta te th tr uk ur uz vi zh-CN zh-TW"

inherit brave chromium-2 desktop eapi9-pipestatus pax-utils unpacker verify-sig xdg

DESCRIPTION="The minimalist browser from the makers of Brave."
HOMEPAGE="https://brave.com/origin/"

MY_PN="brave-origin"

BASE_URI="https://github.com/brave/brave-browser/releases/download/v${PV}"
for _arch in amd64 arm64; do
	SRC_URI+="
		${_arch}? (
			${BASE_URI}/${MY_PN}_${PV}_${_arch}.deb
			verify-sig? (
				${BASE_URI}/${MY_PN}_${PV}_${_arch}.deb.sha256
				${BASE_URI}/${MY_PN}_${PV}_${_arch}.deb.sha256.asc
			)
		)
	"
done
unset _arch
S=${WORKDIR}

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="-* amd64 arm64"

IUSE="qt6 selinux"

RESTRICT="bindist mirror strip"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	>=dev-libs/nss-3.26
	media-fonts/liberation-fonts
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-misc/curl
	net-print/cups
	sys-apps/dbus
	sys-libs/glibc
	sys-libs/libcap
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	|| (
		x11-libs/gtk+:3[X]
		gui-libs/gtk:4[X]
	)
	x11-libs/libdrm
	>=x11-libs/libX11-1.5.0
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/libxshmfence
	x11-libs/pango
	x11-misc/xdg-utils
	qt6? ( dev-qt/qtbase:6[gui,widgets] )
	selinux? ( sec-policy/selinux-chromium )
"

BDEPEND="verify-sig? ( >=sec-keys/openpgp-keys-brave-browser-release-20250709 )"
VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/brave-browser-release.asc

QA_PREBUILT="*"
QA_DESKTOP_FILE="usr/share/applications/${PN}.*\\.desktop"
BRAVE_HOME="opt/brave.com/${MY_PN}"

pkg_pretend() {
	use amd64 || die "brave-origin only works on amd64"
}

pkg_setup() {
	chromium_suid_sandbox_check_kernel_config
}

src_unpack() {
	if use verify-sig; then
		local deb_file="${MY_PN}_${PV}_${ARCH}.deb"
		pushd "${DISTDIR}" > /dev/null || die
		verify-sig_verify_detached "${deb_file}.sha256"{,.asc}
		{ cat "${deb_file}.sha256"; echo; } | \
			verify-sig_verify_unsigned_checksums - sha256 "${deb_file}"
		pipestatus || die
		popd > /dev/null || die
	fi

	unpacker
}

src_install() {
	dodir /
	cd "${ED}" || die
	mv "${S}"/* . || die

	mv usr/share/doc/${MY_PN} usr/share/doc/${PF} || die
	if [[ -d "usr/share/doc/${MY_PN}-stable" ]]; then
		shopt -s nullglob
		local stable_doc_files=( "usr/share/doc/${MY_PN}-stable"/* )
		if [[ ${#stable_doc_files[@]} -gt 0 ]]; then
			mv "${stable_doc_files[@]}" usr/share/doc/${PF}/ || die
		fi
		shopt -u nullglob
		rmdir "usr/share/doc/${MY_PN}-stable" || die
	fi

	# bundled cron scripts invoke `apt` directly, utterly useless (and broken) on Gentoo.
	if [[ -d etc/cron.daily ]]; then
		rm -r etc/cron.daily || die "Failed to remove cron scripts"
	fi
	if [[ -d "${BRAVE_HOME}/cron" ]]; then
		rm -r "${BRAVE_HOME}/cron" || die "Failed to remove cron scripts"
	fi

	gzip -d usr/share/doc/${PF}/changelog.gz || die
	gzip -d "usr/share/man/man1/${MY_PN}-stable.1.gz" || die
	if [[ -L "usr/share/man/man1/${MY_PN}.1.gz" ]]; then
		rm "usr/share/man/man1/${MY_PN}.1.gz" || die
		dosym "${MY_PN}-stable.1" "/usr/share/man/man1/${MY_PN}.1"
	fi

	mv usr/share/{appdata,metainfo}/ || die

	pushd "${BRAVE_HOME}/locales" > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die

	pushd "${BRAVE_HOME}/resources/brave_extension/_locales" > /dev/null || die
	brave_remove_language_dirs
	popd > /dev/null || die

	if [[ -f "${BRAVE_HOME}/libqt5_shim.so" ]]; then
		rm "${BRAVE_HOME}/libqt5_shim.so" || die
	fi
	if ! use qt6; then
		[[ -f "${BRAVE_HOME}/libqt6_shim.so" ]] && rm "${BRAVE_HOME}/libqt6_shim.so" || die
	fi

	local size icon_installed=0
	for size in 16 24 32 48 64 128 256; do
		[[ -f "${BRAVE_HOME}/product_logo_${size}.png" ]] && \
			newicon -s ${size} "${BRAVE_HOME}/product_logo_${size}.png" ${PN}.png && \
			icon_installed=1
	done
	[[ ${icon_installed} -eq 0 ]] && die "No program icons could be installed."

	pax-mark m "${BRAVE_HOME}/brave"
}

pkg_postinst() {
	[[ ${ARCH} == "arm64" ]] && \
		ewarn "Note: arm64 support is experimental for this package and is not currently tested in CI."
}
