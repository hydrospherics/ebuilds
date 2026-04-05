# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Just when you wonder how minimal could it get.. but usable.. and GNOME."
HOMEPAGE="https://www.gnome.org/"

S="${WORKDIR}"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+gnome-shell"

RDEPEND="
	>=gnome-base/gnome-core-libs-50.0
	>=gnome-base/gnome-session-50.0
	>=gnome-base/gnome-settings-daemon-50.0
	>=gnome-base/gnome-control-center-50.0
	>=gnome-base/gdm-50.0

	gnome-shell? (
		>=x11-wm/mutter-50.0
		>=gnome-base/gnome-shell-50.0
		media-fonts/adwaita-fonts
	)

	>=x11-themes/adwaita-icon-theme-49.0
"

pkg_postinst() {
	elog "Obligatory message but please remember to look at https://wiki.gentoo.org/wiki/Project:GNOME"
	elog "for information about the project and documentation."
}
