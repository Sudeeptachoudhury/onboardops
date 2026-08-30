#!/bin/bash

set -euo pipefail

# ============================================================
# OnboardOps Provisioning Kit
# RHEL 9 / RHEL 10
# RH124 Foundation Project
# ============================================================

GROUP="devteam"

USER1="devuser1"
USER2="devuser2"
USER3="devuser3"

ADMIN_USER="$USER1"

SHARED_DIR="/shared/project"
SUDOERS_FILE="/etc/sudoers.d/onboardops"

USERS=("$USER1" "$USER2" "$USER3")

echo "============================================================"
echo "        OnboardOps Provisioning Kit"
echo "============================================================"

# ------------------------------------------------------------
# Root check
# ------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Please run this script as root."
    exit 1
fi

# ------------------------------------------------------------
# Check required commands
# ------------------------------------------------------------

for cmd in groupadd useradd usermod chage passwd \
           chmod chown visudo id getent; do

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $cmd"
        exit 1
    fi

done

echo "[1/7] Creating group: $GROUP"

# ------------------------------------------------------------
# Group creation
# ------------------------------------------------------------

if getent group "$GROUP" >/dev/null 2>&1; then
    echo "Group $GROUP already exists."
else
    groupadd "$GROUP"
    echo "Group $GROUP created."
fi

# ------------------------------------------------------------
# User creation
# ------------------------------------------------------------

echo
echo "[2/7] Creating users"

for user in "${USERS[@]}"; do

    if id "$user" >/dev/null 2>&1; then
        echo "User $user already exists."
    else
        useradd \
            -m \
            -s /bin/bash \
            "$user"

        echo "User $user created."
    fi

    # Add user to devteam supplementary group
    usermod -aG "$GROUP" "$user"

    # Password policy
    chage \
        -M 60 \
        -W 7 \
        -d 0 \
        "$user"

    echo "Password policy configured for $user."

done

# ------------------------------------------------------------
# Password setup
# ------------------------------------------------------------

echo
echo "[3/7] Setting temporary passwords"

echo
echo "Set password for $USER1"
passwd "$USER1"

echo
echo "Set password for $USER2"
passwd "$USER2"

echo
echo "Set password for $USER3"
passwd "$USER3"

# ------------------------------------------------------------
# Sudo configuration
# ------------------------------------------------------------

echo
echo "[4/7] Configuring sudo access"

cat > "$SUDOERS_FILE" <<EOF
# OnboardOps - only $ADMIN_USER receives full sudo access
$ADMIN_USER ALL=(ALL) ALL
EOF

chmod 440 "$SUDOERS_FILE"

# Validate sudoers file
visudo -cf "$SUDOERS_FILE"

echo "Sudo access granted only to $ADMIN_USER."

# ------------------------------------------------------------
# Shared directory
# ------------------------------------------------------------

echo
echo "[5/7] Configuring shared project directory"

mkdir -p "$SHARED_DIR"

chown root:"$GROUP" "$SHARED_DIR"

# 2 = SGID
# 1 = Sticky bit
# 770 = rwxrwx---
chmod 3770 "$SHARED_DIR"

echo "Shared directory configured:"
echo "  Directory : $SHARED_DIR"
echo "  Owner     : root"
echo "  Group     : $GROUP"
echo "  Mode      : 3770"

# ------------------------------------------------------------
# User umask
# ------------------------------------------------------------

echo
echo "[6/7] Configuring umask"

for user in "${USERS[@]}"; do

    USER_HOME=$(getent passwd "$user" | cut -d: -f6)

    if ! grep -qE '^[[:space:]]*umask[[:space:]]+0007' \
        "$USER_HOME/.bashrc" 2>/dev/null; then

        echo "" >> "$USER_HOME/.bashrc"
        echo "# OnboardOps shared project umask" >> "$USER_HOME/.bashrc"
        echo "umask 0007" >> "$USER_HOME/.bashrc"

    fi

    chown "$user":"$user" "$USER_HOME/.bashrc"

done

echo "umask 0007 configured for all three users."

# ------------------------------------------------------------
# Verification
# ------------------------------------------------------------

echo
echo "[7/7] Running basic verification"

echo
echo "---------- GROUP ----------"
getent group "$GROUP"

echo
echo "---------- USERS ----------"

for user in "${USERS[@]}"; do
    id "$user"
done

echo
echo "---------- SHARED DIRECTORY ----------"

ls -ld "$SHARED_DIR"

echo
echo "---------- SUDOERS ----------"

cat "$SUDOERS_FILE"

echo
echo "---------- SUDOERS VALIDATION ----------"

visudo -c

echo
echo "============================================================"
echo "Provisioning completed successfully."
echo "============================================================"

echo
echo "Users:"
printf '  %s\n' "${USERS[@]}"

echo
echo "Sudo user:"
echo "  $ADMIN_USER"

echo
echo "Shared directory:"
echo "  $SHARED_DIR"

echo
echo "Expected directory mode:"
echo "  3770"

echo
echo "Expected umask:"
echo "  0007"

echo
echo "Password policy:"
echo "  Maximum age : 60 days"
echo "  Warning     : 7 days"
echo "  First login : Password change required"
