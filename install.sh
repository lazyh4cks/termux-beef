#!/data/data/com.termux/files/usr/bin/bash
#
# Created by: beefproject
# Brought to you by: lazyh4cks

echo Installing dependences...
sleep 1
pkg install curl wget libyaml libxslt bison espeak ruby python nodejs -y
git clone https://github.com/beefproject/beef
echo Installing Gem...
sleep 1
gem install nokogiri -- --use-system-libraries
cd beef && rm -rf install
echo 
set -euo pipefail
NORMIFS=$IFS
SCRIFS=$'\n\t'
IFS=$SCRIFS

info() { echo -e "\\033[1;36m[INFO]\\033[0m  $*"; }
warn() { echo -e "\\033[1;33m[WARNING]\\033[0m  $*"; }
fatal() {
	echo -e "\\033[1;31m[FATAL]\\033[0m  $*"
	exit 1
}

RUBYSUFFIX=''

command_exists() {

	command -v "${1}" >/dev/null 2>&1
}

get_permission() {

	warn 'This script will install BeEF and its required dependencies (including operating system packages).'

	read -rp "Are you sure you wish to continue (Y/n)? "
	if [ "$(echo "${REPLY}" | tr "[:upper:]" "[:lower:]")" = "n" ]; then
		fatal 'Installation aborted'
	fi

}

check_os() {

	info "Detecting OS..."

	OS=$(uname)
	readonly OS
	info "Operating System: $OS"
	if [ "${OS}" = "Linux" ]; then
		info "Launching Linux install..."
		install_linux
	elif [ "${OS}" = "Darwin" ]; then
		info "Launching Mac OSX install..."
		install_mac
	elif [ "${OS}" = "FreeBSD" ]; then
		info "Launching FreeBSD install..."
		for SUFX in 32 31 30; do
			if command_exists ruby${SUFX}; then
				RUBYSUFFIX=${SUFX}
				break
			fi
		done
		install_freebsd
	elif [ "${OS}" = "OpenBSD" ]; then
		info "Launching OpenBSD install..."
		for SUFX in 32 31 30; do
			if command_exists ruby${SUFX}; then
				RUBYSUFFIX=${SUFX}
				break
			fi
		done
		install_openbsd
	else
		fatal "Unable to locate installer for your operating system: ${OS}"
	fi
}

install_linux() {

	info "Detecting Linux OS distribution..."

	Distro=''
	if [ -f /etc/blackPanther-release ]; then
		Distro='blackPanther'
	elif [ -f /etc/redhat-release ]; then
		Distro='RedHat'
	elif [ -f /etc/debian_version ]; then
		Distro='Debian'
	elif [ -f /etc/alpine-release ]; then
		Distro='Alpine'
	elif [ -f /etc/os-release ]; then
		#DISTRO_ID=$(grep ^ID= /etc/os-release | cut -d= -f2-)
		DISTRO_ID=$(grep ID= /etc/os-release | grep -v "BUILD" | grep -v "IMAGE" | cut -d= -f2-)
		if [ "${DISTRO_ID}" = 'kali' ]; then
			Distro='Kali'
		elif [ "${DISTRO_ID}" = 'arch' ] || [ "${DISTRO_ID}" = 'garuda' ] || [ "${DISTRO_ID}" = 'artix' ] || [ "${DISTRO_ID}" = 'manjaro' ] || [ "${DISTRO_ID}" = 'blackarch' ] || [ "${DISTRO_ID}" = 'arcolinux' ]; then
			Distro='Arch'
		elif grep -Eqi '^ID.*suse' /etc/os-release; then
			Distro='SuSE'
		fi
	fi

	if [ -z "${Distro}" ]; then
		fatal "Unable to locate installer for your ${OS} distribution"
	fi
	readonly Distro
	info "OS Distribution: ${Distro}"
	info "Installing ${Distro} prerequisite packages..."
	if [ "${Distro}" = "Debian" ] || [ "${Distro}" = "Kali" ]; then
		apt-get update
		apt-get install curl git build-essential openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool bison nodejs libcurl4-openssl-dev
		if command_exists rvm || command_exists rbenv; then
			info "Ruby package Manager exists - Ruby install skipped"
		else
			info "No Ruby package manager detected - will install Ruby"
			apt-get install ruby-dev
		fi
	elif [ "${Distro}" = "RedHat" ]; then
		yum install -y git make gcc openssl-devel gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel bzip2 autoconf automake libtool bison sqlite-devel nodejs
	elif [ "${Distro}" = "SuSE" ]; then
		IFS=$NORMIFS
		intpkg=""
		nodejsver=nodejs16

		# having NodeJS 18 installed should mean NodeJS 16 is not needed
		rpm --quiet -q nodejs18 && nodejsver=""

		for i in git make gcc libopenssl-devel gcc-c++ patch libreadline6 readline6-devel libz1 zlib-devel libyaml-devel libffi-devel bzip2 autoconf automake libtool bison sqlite3-devel $nodejsver; do
			rpm --quiet -q "${i}" || intpkg="${intpkg} ${i}"
		done
		[ "$intpkg" ] && zypper -n install -l "${intpkg}"
		IFS=$SCRIFS
	elif [ "${Distro}" = "blackPanther" ]; then
		installing --auto git make gcc openssl-devel gcc-c++ patch readline-devel zlib-devel yaml-devel libffi-devel bzip2 autoconf automake libtool bison sqlite-devel nodejs
	elif [ "${Distro}" = "Arch" ]; then
		pacman -Syu
		pacman -S curl git make openssl gcc readline zlib libyaml sqlite bzip2 autoconf automake libtool bison nodejs
		if command_exists rvm || command_exists rbenv; then
			info "Ruby package Manager exists - Ruby install skipped"
		else
			info "No Ruby package manager detected - will install Ruby"
			pacman -S ruby ruby-rdoc
		fi
	elif [ "${Distro}" = "Alpine" ]; then
		apk update
		apk add curl git build-base openssl readline-dev zlib zlib-dev libressl-dev yaml-dev sqlite-dev sqlite libxml2-dev libxslt-dev autoconf libc6-compat ncurses5 automake libtool bison nodejs
	fi
}

install_openbsd() {

	pkg_add curl git libyaml libxml libxslt bison node ruby${RUBYSUFFIX}-bundler lame espeak
}

install_freebsd() {

	pkg install curl git libyaml libxslt devel/ruby-gems bison node espeak
}

install_mac() {

	local mac_deps=(curl git nodejs python3
		openssl readline libyaml sqlite3 libxml2
		autoconf ncurses automake libtool
		bison wget)

	if ! command_exists brew; then
		fatal "Homebrew (https://brew.sh/) required to install dependencies"
	fi

	info "Installing dependencies via brew"

	brew update

	for package in "${mac_deps[@]}"; do

		if brew install "${package}"; then
			info "${package} installed"
		else
			fatal "Failed to install ${package}"
		fi

	done
}

check_ruby_version() {

	info 'Detecting Ruby environment...'

	MIN_RUBY_VER='3.0'
	if command_exists rvm; then
		RUBY_VERSION=$(rvm current | cut -d'-' -f 2)
		info "Ruby version ${RUBY_VERSION} is installed with RVM"
		if RUBY_VERSION -lt MIN_RUBY_VER; then
			fatal "Ruby version ${RUBY_VERSION} is not supported. Please install Ruby ${MIN_RUBY_VER} (or newer) and restart the installer."
		fi
	elif command_exists rbenv; then
		RUBY_VERSION=$(rbenv version | cut -d' ' -f 2)
		info "Ruby version ${RUBY_VERSION} is installed with rbenv"
		if RUBY_VERSION -lt MIN_RUBY_VER; then
			fatal "Ruby version ${RUBY_VERSION} is not supported. Please install Ruby ${MIN_RUBY_VER} (or newer) and restart the installer."
		fi
	elif command_exists ruby${RUBYSUFFIX}; then
		RUBY_VERSION=$(ruby${RUBYSUFFIX} -e "puts RUBY_VERSION")
		info "Ruby version ${RUBY_VERSION} is installed"
		if [ "$(ruby${RUBYSUFFIX} -e "puts RUBY_VERSION.to_f >= ${MIN_RUBY_VER}")" = 'false' ]; then
			fatal "Ruby version ${RUBY_VERSION} is not supported. Please install Ruby ${MIN_RUBY_VER} (or newer) and restart the installer."
		fi
	else
		fatal "Ruby is not installed. Please install Ruby ${MIN_RUBY_VER} (or newer) and restart the installer."
	fi
}

check_bundler() {

	info 'Detecting bundler gem...'

	if command_exists bundler${RUBYSUFFIX}; then
		info "bundler${RUBYSUFFIX} gem is installed"
	else
		info 'Installing bundler gem...'
		gem${RUBYSUFFIX} install bundler
	fi
}

install_beef() {

	echo "Installing required Ruby gems..."

	if [ -w Gemfile.lock ]; then
		/bin/rm Gemfile.lock
	fi

	if command_exists bundle${RUBYSUFFIX}; then
		bundle${RUBYSUFFIX} install
	else
		bundle install
	fi
}

finish() {
	echo
	echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
	echo
	info "Install completed successfully!"
	info "Run './beef' to launch BeEF"
	echo
	echo "Next steps:"
	echo
	echo "* Change the default password in config.yaml"
	echo "* Configure geoipupdate to update the Maxmind GeoIP database."
	echo "* Review the wiki for important configuration information:"
	echo "  https://github.com/beefproject/beef/wiki/Configuration"
	echo
	echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
	echo
}

main() {

	clear

	if [ -f core/main/console/beef.ascii ]; then
		cat core/main/console/beef.ascii
		echo
	fi

	echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
	echo "                   -- [ BeEF Installer ] --   "
	echo "                 -- Modificado por lazyh4cks --    "
  echo "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#"
	echo

	if [ -n "${GITACTIONS:-}" ]; then
		info "Skipping: Running on Github Actions"
	else
		get_permission
	fi
	check_bundler
	install_beef
	finish
}

main "$@" > install.sh
bash install.sh



