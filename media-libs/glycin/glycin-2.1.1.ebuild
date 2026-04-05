# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER=1.92.0

inherit cargo gnome2-utils meson

MY_PV=${PV/_/.}
MY_P=glycin-${MY_PV}

DESCRIPTION="Sandboxed image decoding library"
HOMEPAGE="https://gitlab.gnome.org/GNOME/glycin/"
SRC_URI="
	https://gitlab.gnome.org/GNOME/glycin/-/archive/${MY_PV}/${MY_P}.tar.bz2
	https://github.com/gentoo-crate-dist/glycin/releases/download/${MY_PV}/${MY_P}-crates.tar.xz
"
S=${WORKDIR}/${MY_P}

LICENSE="|| ( LGPL-2.1+ MPL-2.0 )"
# licenses for dependent crates
LICENSE+="
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions
	Boost-1.0 BSD BSD-2 CC0-1.0 GPL-3+ IJG ISC
	LGPL-2.1+ LGPL-3+ MIT MIT-0 MPL-2.0
	Unicode-3.0 Unlicense ZLIB
"

SLOT="2"
KEYWORDS="~amd64"
IUSE="gtk +introspection vala"
REQUIRED_USE="vala? ( introspection )"

RDEPEND="
	>=dev-libs/glib-2.68.0:2
	>=sys-libs/libseccomp-2.5.0
	>=media-libs/lcms-2.14:2
	>=media-libs/fontconfig-2.13.0
	~media-libs/glycin-loaders-${PV}
	gtk? ( >=gui-libs/gtk-4.16.0:4 )
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-build/meson-1.2
	introspection? ( dev-libs/gobject-introspection )
	vala? ( dev-lang/vala )
"

src_configure() {
	local emesonargs=(
		-Dprofile=$(usex debug dev release)
		-Dlibglycin=true
		-Dlibglycin-gtk4=$(usex gtk true false)
		-Dintrospection=$(usex introspection true false)
		-Dvapi=$(usex vala true false)
		-Dglycin-loaders=false
		-Dglycin-thumbnailer=false
		-Dtests=false
	)

	meson_src_configure
	ln -s "${CARGO_HOME}" "${BUILD_DIR}/cargo-home" || die
}

src_install() {
	meson_src_install
}

pkg_postinst() {
	gnome2_schemas_update
}

pkg_postrm() {
	gnome2_schemas_update
}
