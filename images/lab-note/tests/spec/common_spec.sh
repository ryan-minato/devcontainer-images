Describe "Common Checks"
    Describe "OS Packages"
        check_os_packages() {
            PACKAGE_LIST="apt-utils \
            git \
            openssh-client \
            less \
            iproute2 \
            procps \
            curl \
            wget \
            unzip \
            nano \
            jq \
            lsb-release \
            ca-certificates \
            apt-transport-https \
            dialog \
            gnupg2 \
            libc6 \
            libgcc1 \
            libgssapi-krb5-2 \
            liblttng-ust1 \
            libstdc++6 \
            zlib1g \
            locales \
            sudo"

            if dpkg-query --show -f='${Package}: ${Version}\n' "$@" >> /dev/null; then
                return 0
            else
                return 1
            fi
        }
        It "All OS packages are installed"
            When call check_os_packages
            The status should be success
        End
        It "zsh is installed"
            When call zsh --version
            The output should include "zsh"
        End
        It "bash is installed"
            When call bash --version
            The output should include "bash"
        End
        It "wget is installed"
            When call wget --version
            The output should include "wget"
        End
        It "curl is installed"
            When call curl --version
            The output should include "curl"
        End
    End

    Describe "User"
        It "Non-root user exists"
            When call id
            The output should not include "(root)"
        End
    End

    Describe "Locale"
        It "Locale is set to en_US.utf8"
            When call locale -a
            The output should include "en_US.utf8"
        End
    End

    Describe "Sudo"
        It "Sudo is installed"
            When call sudo echo "sudo works."
            The output should include "sudo works."
        End
    End
End
