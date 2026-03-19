# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER=1.85.0

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

SLOT="2"
KEYWORDS="~amd64" #keyworded because I can't thoroughly test it yet
IUSE="gtk +introspection vala"

RDEPEND="
	>=dev-libs/glib-2.68.0:2
	>=sys-libs/libseccomp-2.5.0
	media-libs/lcms:2
	x11-libs/fontconfig
	gtk? ( gui-libs/gtk:4 )
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-util/meson-1.2
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
