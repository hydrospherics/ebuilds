# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit desktop gnome.org gnome2-utils meson systemd xdg

DESCRIPTION="Gnome session manager"
HOMEPAGE="https://gitlab.gnome.org/GNOME/gnome-session"
SRC_URI="https://download.gnome.org/sources/gnome-session/50/${P}.tar.xz"
LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="doc"

COMMON_DEPEND="
	>=dev-libs/glib-2.82.0:2
	>=gnome-base/gnome-desktop-40.0:4=
	>=sys-apps/systemd-242:0=
"

RDEPEND="${COMMON_DEPEND}
	>=gnome-base/gnome-settings-daemon-50.0
	>=gnome-base/gsettings-desktop-schemas-50_alpha
	sys-apps/dbus[systemd]
	x11-misc/xdg-user-dirs
	x11-misc/xdg-user-dirs-gtk
"
DEPEND="${COMMON_DEPEND}"
BDEPEND="
	dev-libs/libxslt
	>=dev-util/gdbus-codegen-2.80.5-r1
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
	doc? (
		app-text/xmlto
		app-text/docbook-xml-dtd:4.1.2
	)
"

src_prepare() {
	default
	xdg_environment_reset
}

src_configure() {
	local emesonargs=(
		-Ddeprecation_flags=false
		$(meson_use doc docbook)
		-Dman=true
		-Dmimeapps=false
		-Dsystemduserunitdir="$(systemd_get_userunitdir)"
	)
	meson_src_configure
}

src_install() {
	meson_src_install

	newmenu "${FILESDIR}/defaults.list-r7" gnome-mimeapps.list

	exeinto /etc/X11/xinit/xinitrc.d/
	newexe "${FILESDIR}/15-xdg-data-gnome-r1" 15-xdg-data-gnome
	newexe "${FILESDIR}/10-user-dirs-update-gnome-r1" 10-user-dirs-update-gnome
	newexe "${FILESDIR}/90-xcursor-theme-gnome" 90-xcursor-theme-gnome
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update

	if ! has_version gnome-base/gdm && ! has_version x11-misc/sddm; then
		ewarn "If you use a custom .xinitrc for your X session,"
		ewarn "make sure that the commands in the xinitrc.d scripts are run."
	fi
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
