#!/bin/bash
# This script installs useful binaries and tools for the base image.
# Method from devcontainer/feature
# url: https://github.com/devcontainers/features/blob/main/src/common-utils/main.sh

set -e

UPGRADE_PACKAGES="${UPGRADEPACKAGES:-"true"}"
INSTALL_ZSH="${INSTALL_ZSH:-"true"}"

# Debian / Ubuntu packages
install_debian_packages() {
    # Ensure apt is in non-interactive to avoid prompts
    export DEBIAN_FRONTEND=noninteractive

    local package_list=""
    if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
        package_list="${package_list} \
        apt-utils \
        bash-completion \
        openssh-client \
        gnupg2 \
        dirmngr \
        iproute2 \
        procps \
        lsof \
        htop \
        net-tools \
        psmisc \
        curl \
        tree \
        wget \
        rsync \
        ca-certificates \
        unzip \
        bzip2 \
        xz-utils \
        zip \
        nano \
        vim-tiny \
        less \
        jq \
        lsb-release \
        apt-transport-https \
        dialog \
        libc6 \
        libgcc1 \
        libkrb5-3 \
        libgssapi-krb5-2 \
        libicu[0-9][0-9] \
        liblttng-ust[0-9] \
        libstdc++6 \
        zlib1g \
        locales \
        sudo \
        ncdu \
        man-db \
        strace \
        manpages \
        manpages-dev \
        init-system-helpers"

        # Include libssl1.1 if available
        if [[ ! -z $(apt-cache --names-only search ^libssl1.1$) ]]; then
            package_list="${package_list} libssl1.1"
        fi

        # Include libssl3 if available
        if [[ ! -z $(apt-cache --names-only search ^libssl3$) ]]; then
            package_list="${package_list} libssl3"
        fi

        # Include appropriate version of libssl1.0.x if available
        local libssl_package
        libssl_package=$(dpkg-query -f '${db:Status-Abbrev}\t${binary:Package}\n' -W 'libssl1\.0\.?' 2>&1 || echo '')
        if [ "$(echo "$libssl_package" | grep -o 'libssl1\.0\.[0-9]:' | uniq | sort | wc -l)" -eq 0 ]; then
            if [[ ! -z $(apt-cache --names-only search ^libssl1.0.2$) ]]; then
                # Debian 9
                package_list="${package_list} libssl1.0.2"
            elif [[ ! -z $(apt-cache --names-only search ^libssl1.0.0$) ]]; then
                # Ubuntu 18.04
                package_list="${package_list} libssl1.0.0"
            fi
        fi

        # Include git if not already installed (may be more recent than distro version)
        if ! type git > /dev/null 2>&1; then
            package_list="${package_list} git"
        fi
    fi

    # Install the list of packages
    echo "Packages to verify are installed: ${package_list}"
    rm -rf /var/lib/apt/lists/*
    apt-get update -y
    apt-get -y install --no-install-recommends ${package_list} 2> >( grep -v 'debconf: delaying package configuration, since apt-utils is not installed' >&2 )

    # Install zsh (and recommended packages) if needed
    if [ "${INSTALL_ZSH}" = "true" ] && ! type zsh > /dev/null 2>&1; then
        apt-get install -y zsh
    fi

    # Get to latest versions of all packages
    if [ "${UPGRADE_PACKAGES}" = "true" ]; then
        apt-get -y upgrade --no-install-recommends
        apt-get autoremove -y
    fi

    # Ensure at least the en_US.UTF-8 UTF-8 locale is available = common need for both applications and things like the agnoster ZSH theme.
    if [ "${LOCALE_ALREADY_SET}" != "true" ] && ! grep -o -E '^\s*en_US.UTF-8\s+UTF-8' /etc/locale.gen > /dev/null; then
        echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
        locale-gen
        LOCALE_ALREADY_SET="true"
    fi

    PACKAGES_ALREADY_INSTALLED="true"

    # Clean up
    apt-get -y clean
    rm -rf /var/lib/apt/lists/*
}

# RedHat / RockyLinux / CentOS / Fedora packages
install_redhat_packages() {
    local package_list=""
    local remove_epel="false"
    local install_cmd=microdnf
    if ! type microdnf > /dev/null 2>&1; then
        install_cmd=dnf
        if ! type dnf > /dev/null 2>&1; then
            install_cmd=yum
        fi
    fi

    if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
        package_list="${package_list} \
            gawk \
            bash-completion \
            openssh-clients \
            gnupg2 \
            iproute \
            procps \
            lsof \
            net-tools \
            psmisc \
            wget \
            ca-certificates \
            rsync \
            unzip \
            xz \
            zip \
            nano \
            vim-minimal \
            less \
            jq \
            openssl-libs \
            krb5-libs \
            libicu \
            zlib \
            sudo \
            sed \
            grep \
            which \
            man-db \
            strace"

        # rockylinux:9 installs 'curl-minimal' which clashes with 'curl'
        # Install 'curl' for every OS except this rockylinux:9
        if [[ "${ID}" = "rocky" ]] && [[ "${VERSION}" != *"9."* ]]; then
            package_list="${package_list} curl"
        fi

        # Install OpenSSL 1.0 compat if needed
        if ${install_cmd} -q list compat-openssl10 >/dev/null 2>&1; then
            package_list="${package_list} compat-openssl10"
        fi

        # Install lsb_release if available
        if ${install_cmd} -q list redhat-lsb-core >/dev/null 2>&1; then
            package_list="${package_list} redhat-lsb-core"
        fi

        # Install git if not already installed (may be more recent than distro version)
        if ! type git > /dev/null 2>&1; then
            package_list="${package_list} git"
        fi

        # Install EPEL repository if needed (required to install 'jq' for CentOS)
        if ! ${install_cmd} -q list jq >/dev/null 2>&1; then
            ${install_cmd} -y install epel-release
            remove_epel="true"
        fi
    fi

    # Install zsh if needed
    if [ "${INSTALL_ZSH}" = "true" ] && ! type zsh > /dev/null 2>&1; then
        package_list="${package_list} zsh"
    fi

    if [ -n "${package_list}" ]; then
        ${install_cmd} -y install ${package_list}
    fi

    # Get to latest versions of all packages
    if [ "${UPGRADE_PACKAGES}" = "true" ]; then
        ${install_cmd} upgrade -y
    fi

    if [[ "${remove_epel}" = "true" ]]; then
        ${install_cmd} -y remove epel-release
    fi

    PACKAGES_ALREADY_INSTALLED="true"
}

# Alpine Linux packages
install_alpine_packages() {
    apk update

    if [ "${PACKAGES_ALREADY_INSTALLED}" != "true" ]; then
        apk add --no-cache \
            openssh-client \
            bash-completion \
            gnupg \
            procps \
            lsof \
            htop \
            net-tools \
            psmisc \
            curl \
            wget \
            rsync \
            ca-certificates \
            unzip \
            xz \
            zip \
            nano \
            vim \
            less \
            jq \
            libgcc \
            libstdc++ \
            krb5-libs \
            libintl \
            lttng-ust \
            tzdata \
            userspace-rcu \
            zlib \
            sudo \
            coreutils \
            sed \
            grep \
            which \
            ncdu \
            shadow \
            strace

        # # Include libssl1.1 if available (not available for 3.19 and newer)
        LIBSSL1_PKG=libssl1.1
        if [[ $(apk search --no-cache -a $LIBSSL1_PKG | grep $LIBSSL1_PKG) ]]; then
            apk add --no-cache $LIBSSL1_PKG
        fi

        # Install man pages - package name varies between 3.12 and earlier versions
        if apk info man > /dev/null 2>&1; then
            apk add --no-cache man man-pages
        else
            apk add --no-cache mandoc man-pages
        fi

        # Install git if not already installed (may be more recent than distro version)
        if ! type git > /dev/null 2>&1; then
            apk add --no-cache git
        fi
    fi

    # Install zsh if needed
    if [ "${INSTALL_ZSH}" = "true" ] && ! type zsh > /dev/null 2>&1; then
        apk add --no-cache zsh
    fi

    PACKAGES_ALREADY_INSTALLED="true"
}

install_common_urils() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
        exit 1
    fi

    # Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
    . /etc/os-release
    # Get an adjusted ID independent of distro variants
    if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
        ADJUSTED_ID="debian"
    elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
        ADJUSTED_ID="rhel"
        VERSION_CODENAME="${ID}${VERSION_ID}"
    elif [ "${ID}" = "alpine" ]; then
        ADJUSTED_ID="alpine"
    else
        echo "Linux distro ${ID} not supported."
        exit 1
    fi

    if [ "${ADJUSTED_ID}" = "rhel" ] && [ "${VERSION_CODENAME-}" = "centos7" ]; then
        # As of 1 July 2024, mirrorlist.centos.org no longer exists.
        # Update the repo files to reference vault.centos.org.
        sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
        sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
        sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
    fi

    if [ "${ADJUSTED_ID}" = "rhel" ] && [ "${VERSION_CODENAME-}" = "centos7" ]; then
        # As of 1 July 2024, mirrorlist.centos.org no longer exists.
        # Update the repo files to reference vault.centos.org.
        sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
        sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
        sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
    fi

    # Install packages for appropriate OS
    echo "Detecting OS: ${ID} ${VERSION_ID} ${VERSION_CODENAME}"
    case "${ADJUSTED_ID}" in
        "debian")
            echo "Installing Debian packages..."
            install_debian_packages
            ;;
        "rhel")
            echo "Installing RedHat packages..."
            install_redhat_packages
            ;;
        "alpine")
            echo "Installing Alpine packages..."
            install_alpine_packages
            ;;
    esac

    echo "Done!"
}


### Main script

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --upgrade-packages|-u)
            UPGRADE_PACKAGES="true"
            ;;
        --no-upgrade-packages)
            UPGRADE_PACKAGES="false"
            ;;
        --install-zsh|-z)
            INSTALL_ZSH="true"
            ;;
        --no-install-zsh)
            INSTALL_ZSH="false"
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --upgrade-packages, -u: Upgrade all packages to the latest versions"
            echo "  --no-upgrade-packages: Do not upgrade packages"
            echo "  --install-zsh, -z: Install zsh"
            echo "  --no-install-zsh: Do not install zsh"
            exit 0
            ;;
        *)
            echo "Unrecognized argument: $1"
            exit 1
            ;;
    esac
    shift
done

install_common_urils
