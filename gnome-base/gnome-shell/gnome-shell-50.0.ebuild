# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{11..14} )

inherit flag-o-matic gnome.org gnome2-utils meson optfeature python-single-r1 virtualx xdg

DESCRIPTION="Provides core UI functions for the GNOME desktop"
HOMEPAGE="https://gitlab.gnome.org/GNOME/gnome-shell"

LICENSE="GPL-2+ LGPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~loong ~ppc64 ~riscv ~x86"

IUSE="gtk-doc +ibus +networkmanager +pipewire systemd test xwayland"
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	^^ ( systemd )
	networkmanager? ( pipewire )"
# portal_helper requires networkmanager per meson.build line 114
# pipewire gates camera_monitor
RESTRICT="!test? ( test )"

# Notes:
# girepository-2.0 is now part of dev-libs/glib since 2.86
# gvc and libshew are bundled subprojects, no external dep needed
# xwayland support is inherited from mutter's build flags, not a meson option
# libpulse removed upstream in gnome-shell 50
# gnome-desktop:3 dep removed, only :4 is used now
DEPEND="
	>=dev-libs/glib-2.86.0:2
	>=dev-libs/gobject-introspection-1.82.0:=
	>=dev-libs/gjs-1.87.1[cairo(+)]
	>=gui-libs/gtk-4.0:4[introspection,wayland]
	>=x11-wm/mutter-50.0:0/18[introspection,test?,xwayland?]
	>=gnome-extra/evolution-data-server-3.33.1:=
	>=app-crypt/gcr-3.90.0:4=[introspection]
	>=sys-auth/polkit-0.100[introspection]
	>=gnome-base/gsettings-desktop-schemas-50_alpha[introspection]
	>=gnome-base/gnome-desktop-40.0:4=
	>=x11-libs/pango-1.46.0[introspection]
	x11-libs/gdk-pixbuf:2[introspection]
	>=app-accessibility/at-spi2-core-2.46:2[introspection]
	dev-libs/libxml2:2=
	dev-libs/json-glib
	app-arch/gnome-autoar
	dev-libs/libical:=
	media-libs/libglvnd

	ibus? ( >=app-i18n/ibus-1.5.19 )

	networkmanager? (
		>=net-misc/networkmanager-1.10.4[introspection]
		net-libs/libnma[introspection]
		>=app-crypt/libsecret-0.18
	)
	pipewire? ( >=media-video/pipewire-0.3.49:= )
	systemd? ( >=sys-apps/systemd-246:= )

	xwayland? (
		x11-libs/libX11
		x11-libs/libXext
		>=x11-libs/libXfixes-5.0
	)

	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pygobject:3[${PYTHON_USEDEP}]
	')
"
RDEPEND="${DEPEND}
	>=sys-apps/accountsservice-0.6.14[introspection]
	app-accessibility/at-spi2-core:2[introspection]
	app-misc/geoclue:2.0[introspection]
	media-libs/graphene[introspection]
	net-libs/libsoup:3.0[introspection]
	>=sys-power/upower-0.99:=[introspection]
	gnome-base/librsvg:2[introspection]
	gui-libs/libadwaita:1[introspection]

	>=gnome-base/gnome-session-50.0
	>=gnome-base/gnome-settings-daemon-50.0

	x11-misc/xdg-utils
	>=x11-themes/adwaita-icon-theme-3.26
	media-fonts/adwaita-fonts

	sys-apps/xdg-desktop-portal-gnome

	ibus? ( >=app-i18n/ibus-1.5.26[gtk3,gtk4,introspection] )

	networkmanager? (
		net-misc/mobile-broadband-provider-info
		sys-libs/timezone-data
	)
"
# avoid circular dependency, see bug #546134
PDEPEND="
	>=gnome-base/gdm-3.5[introspection(+)]
	>=gnome-base/gnome-control-center-3.26[networkmanager(+)?]
"
BDEPEND="
	>=dev-build/meson-1.3.0
	dev-libs/libxslt
	>=dev-util/gdbus-codegen-2.80.5
	dev-util/glib-utils
	dev-python/docutils
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
	gtk-doc? (
		>=dev-util/gi-docgen-2021.1
		app-text/docbook-xml-dtd:4.5
	)
	test? (
		sys-apps/dbus
		x11-wm/mutter[test]
	)
"

src_prepare() {
	default
	xdg_environment_reset
	sed -e "s:python\.full_path():'/usr/bin/env ${EPYTHON}':" -i src/meson.build || die
}

src_configure() {
	local emesonargs=(
		$(meson_use pipewire camera_monitor)
		-Dextensions_tool=true
		-Dextensions_app=true
		$(meson_use gtk-doc gtk_doc)
		-Dman=true
		$(meson_use test tests)
		$(meson_use networkmanager)
		$(meson_use networkmanager portal_helper)
		$(meson_use systemd)
	)
	meson_src_configure
}

src_test() {
	gnome2_environment_reset
	export XDG_DATA_DIRS="${EPREFIX}"/usr/share
	virtx dbus-run-session meson test -C "${BUILD_DIR}" || die
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update

	if ! has_version "media-libs/mesa[llvm]"; then
		elog "llvmpipe is used as fallback when no 3D acceleration"
		elog "is available. You will need to enable llvm USE for"
		elog "media-libs/mesa if you do not have hardware 3D setup."
	fi

	optfeature "Bluetooth integration" gnome-base/gnome-control-center[bluetooth] net-wireless/gnome-bluetooth:3[introspection]
	optfeature "Browser extension integration" gnome-extra/gnome-browser-connector
	optfeature "Weather support" dev-libs/libgweather:4[introspection]
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
