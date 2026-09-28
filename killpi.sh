#!/system/bin/sh
# Falcon Integrity Fix - Kill GMS & Play Store Processes

if [ "$USER" != "root" ] && [ "$(whoami 2>/dev/null)" != "root" ]; then
  echo "killpi: root permissions required";
  exit 1;
fi;

# Kill Google Play Services DroidGuard and Play Store processes
TARGET_PACKAGES="com.google.android.gms.unstable com.android.vending"

for PKG in $TARGET_PACKAGES; do
    killall -v "$PKG" 2>/dev/null || pkill -f "$PKG" 2>/dev/null || am force-stop "$PKG" 2>/dev/null
done