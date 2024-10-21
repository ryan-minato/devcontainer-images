#!/bin/bash

set -e


# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        # --user(-u): The username to create, defaults to dev
        --user|-u)
            username=${2:-dev}
            shift
            ;;
        # --user_uid: The user ID to assign to the user, defaults to 1000
        --user_uid|-i)
            user_uid=${2:-1000}
            shift
            ;;
        # --user_gid: The group ID to assign to the user, defaults to same as user ID
        --user_gid|-g)
            user_gid=${2:-""}
            shift
            ;;
        # --force(-f): Force overwrite of existing user
        --force|-f)
            force=true
            ;;
        --help|-h)
            echo "Usage: $0 [--user(-u) <username>] [--user_uid <user_id>] [--user_gid <group_id>] [--force(-f)]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
    shift
done

if [ -z "$user_gid" ]; then
    user_gid=$user_uid
fi

echo "Adding non-root user: $username"
echo "User ID: $user_uid"
echo "Group ID: $user_gid"

# Check if user exists uid
if id -u "$user_uid" &>/dev/null; then
    if [ -z "$force" ]; then
        echo "User ID $user_uid already exists, use --force to overwrite"
        exit 1
    else
        echo "User ID $user_uid already exists, overwriting"
        userdel -r "$(id -nu "$user_uid")"
    fi
fi

groupadd --gid "$user_gid" "$username"
useradd --uid "$user_uid" --gid "$user_gid" -m "$username"
apt-get update
apt-get install -y sudo
echo "$username" ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/$username"
chmod 0440 "/etc/sudoers.d/$username"
