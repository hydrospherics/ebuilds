# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit gnome.org gnome2-utils meson readme.gentoo-r1 virtualx xdg

DESCRIPTION="Default file manager for the GNOME desktop"
HOMEPAGE="https://apps.gnome.org/Nautilus/"
SRC_URI="https://download.gnome.org/sources/nautilus/50/${P}.tar.xz"
LICENSE="GPL-3+ LGPL-2.1+"
SLOT="0"

KEYWORDS="~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~x86"

IUSE="+cloudproviders doc +extensions +introspection previewer selinux test"
REQUIRED_USE="doc? ( introspection )"
RESTRICT="!test? ( test )"

DEPEND="
	>=dev-libs/glib-2.84.0:2
	>=gui-libs/gtk-4.20.0:4[introspection?,wayland]
	>=gui-libs/libadwaita-1.8_alpha:1
	>=app-arch/gnome-autoar-0.4.4
	>=gnome-base/gnome-desktop-43.0:4=
	>=dev-libs/libportal-0.7:=[gtk]
	>=dev-libs/icu-56:=
	>=app-misc/tinysparql-3.8:3
	>=media-libs/glycin-2.0.0_beta2:2
	dev-libs/wayland
	selinux? ( >=sys-libs/libselinux-2.0 )
	cloudproviders? ( >=net-libs/libcloudproviders-0.3.1 )
	introspection? ( >=dev-libs/gobject-introspection-1.82.0-r2:= )
	extensions? (
		>=media-libs/gexiv2-0.16.0
		x11-libs/gdk-pixbuf:2
		>=media-libs/gstreamer-1.0:1.0
		>=media-libs/gst-plugins-base-1.0:1.0
	)
"
RDEPEND="${DEPEND}
	>=app-misc/localsearch-3.0:3=
	previewer? ( >=gnome-extra/sushi-0.1.9 )
	>=gnome-base/gvfs-1.14[gtk(+)]
"
BDEPEND="
	>=dev-util/blueprint-compiler-0.19
	>=dev-util/gdbus-codegen-2.80.5-r1
	dev-util/glib-utils
	dev-util/wayland-scanner
	doc? ( dev-util/gi-docgen )
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
	test? ( sys-apps/dbus )
"

src_prepare() {
	default
	xdg_environment_reset

	sed -e '/-Werror=/d' -i meson.build || die

	if use previewer; then
		DOC_CONTENTS="nautilus uses gnome-extra/sushi to preview media files.
			To activate the previewer, select a file and press space; to
			close the previewer, press space again."
	fi
}

src_configure() {
	local emesonargs=(
		$(meson_use doc docs)
		$(meson_use extensions)
		$(meson_use introspection)
		-Dpackagekit=false
		$(meson_feature selinux)
		$(meson_feature cloudproviders)
		-Dtests=$(usex test all none)
	)
	meson_src_configure
}

src_install() {
	use previewer && readme.gentoo_create_doc
	meson_src_install
}

src_test() {
	gnome2_environment_reset
	GIO_USE_VOLUME_MONITOR=unix XDG_SESSION_TYPE=x11 virtx dbus-run-session meson test -C "${BUILD_DIR}" || die
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update

	if use previewer; then
		readme.gentoo_print_elog
	else
		elog "To preview media files, emerge nautilus with USE=previewer"
	fi
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
