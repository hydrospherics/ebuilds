# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{11..14} )

inherit gnome.org gnome2-utils python-any-r1 meson udev virtualx xdg

DESCRIPTION="Gnome Settings Daemon"
HOMEPAGE="https://gitlab.gnome.org/GNOME/gnome-settings-daemon"
SRC_URI="https://download.gnome.org/sources/gnome-settings-daemon/50/${P}.tar.xz"

LICENSE="GPL-2+ LGPL-2+"
SLOT="0"

KEYWORDS="~amd64"

IUSE="+colord +cups debug modemmanager networkmanager smartcard systemd test wayland"
RESTRICT="!test? ( test )"

COMMON_DEPEND="
	>=dev-libs/glib-2.70:2
	>=gnome-base/gnome-desktop-40.0:4=
	>=gnome-base/gsettings-desktop-schemas-46_beta
	>=dev-libs/libgweather-4.2.0:4=
	|| (
		>=sci-geosciences/geocode-glib-3.26.3:2
		>=sci-geosciences/geocode-glib-3.10.0:0
	)
	colord? ( >=x11-misc/colord-1.4.5:= )
	media-libs/libcanberra
	>=app-misc/geoclue-2.3.1:2.0
	>=x11-libs/libnotify-0.8.7
	>=media-libs/libpulse-2.0[glib]
	>=sys-auth/polkit-0.114
	>=sys-power/upower-0.99.12:=
	x11-libs/libX11
	>=x11-libs/libXfixes-6.0.0
	dev-libs/libgudev:=
	wayland? ( dev-libs/wayland )
	smartcard? ( app-crypt/gcr:4= )
	cups? ( >=net-print/cups-1.4[dbus] )
	modemmanager? (
		>=app-crypt/gcr-3.90.0:4=
		>=net-misc/modemmanager-1.18:=
	)
	networkmanager? ( >=net-misc/networkmanager-1.0 )
	media-libs/alsa-lib
	x11-libs/libXi
	x11-libs/libXext
	media-libs/fontconfig
	systemd? ( >=sys-apps/systemd-243 )
	!systemd? ( sys-auth/elogind )
"
DEPEND="${COMMON_DEPEND}
	x11-base/xorg-proto
"
RDEPEND="${COMMON_DEPEND}
	gnome-base/dconf
"
BDEPEND="
	sys-kernel/linux-headers
	dev-util/glib-utils
	>=dev-util/gdbus-codegen-2.80.5-r1
	${PYTHON_DEPS}
	test? (
		dev-util/umockdev
		$(python_gen_any_dep '
			dev-python/pygobject:3[${PYTHON_USEDEP}]
			dev-python/python-dbusmock[${PYTHON_USEDEP}]
		')
		gnome-base/gnome-session
	)
	>=sys-devel/gettext-0.19.8
	virtual/pkgconfig
"

python_check_deps() {
	if use test; then
		python_has_version "dev-python/pygobject:3[${PYTHON_USEDEP}]" &&
		python_has_version "dev-python/python-dbusmock[${PYTHON_USEDEP}]"
	fi
}

pkg_setup() {
	python-any-r1_pkg_setup
}

src_configure() {
	local emesonargs=(
		-Dudev_dir="$(get_udevdir)"
		$(meson_use systemd)
		-Delogind=$(usex systemd false true)
		-Dalsa=true
		-Dgudev=true
		-Dgcr3=false
		$(meson_use colord)
		$(meson_use cups)
		$(meson_use networkmanager network_manager)
		-Drfkill=true
		$(meson_use smartcard)
		-Dusb-protection=true
		$(meson_use wayland xwayland)
		$(meson_use modemmanager wwan)
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	# Don't auto-suspend by default on AC power
	insinto /usr/share/glib-2.0/schemas
	doins "${FILESDIR}"/org.gnome.settings-daemon.plugins.power.gschema.override
}

src_test() {
	virtx meson_src_test
}

pkg_postinst() {
	udev_reload
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	udev_reload
	xdg_pkg_postrm
	gnome2_schemas_update
}
