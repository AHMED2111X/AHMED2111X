#!/system/bin/sh
# ==============================================================================
# FALCON INTEGRITY FIX — Clean Install Helper
# Run this as root BEFORE installing the new zip, to wipe any broken/stale state.
#   sh /sdcard/clean_install.sh   (or via root shell)
# ==============================================================================
set +e

echo "=== FALCON CLEAN INSTALL ==="

# 1) Remove modules (manager will re-register on fresh install)
for D in /data/adb/modules/playintegrityfix /data/adb/modules/falcon_tricky \
         /data/adb/modules_update/playintegrityfix /data/adb/modules_update/falcon_tricky; do
    if [ -d "$D" ]; then
        rm -rf "$D" 2>/dev/null
        if [ -d "$D" ]; then
            touch "$D/disable" "$D/remove" 2>/dev/null
            echo "marked for removal: $D"
        else
            echo "removed: $D"
        fi
    fi
done

# 2) Remove conflicting tricky/safetynet/integrity modules
for RBASE in /data/adb/modules /data/adb/modules_update; do
    [ -d "$RBASE" ] || continue
    for RDIR in "$RBASE"/*; do
        [ -d "$RDIR" ] || continue
        RNAME="${RDIR##*/}"
        case "$RNAME" in
            playintegrityfix|falcon_tricky) continue ;;
        esac
        case "$RNAME" in
            *tricky*|*safetynet*|*playintegrity*|*integrity*|*pif*)
                rm -rf "$RDIR" 2>/dev/null
                echo "removed conflicting: $RNAME"
                ;;
        esac
    done
done

# 3) Wipe /data/adb falcon/tricky/pif state (keybox will be reinstalled from zip)
for D in /data/adb/falcon /data/adb/falcon* /data/adb/tricky* /data/adb/pif* /data/adb/*falcon*; do
    [ -e "$D" ] || continue
    rm -rf "$D" 2>/dev/null
    echo "removed: $D"
done

# 4) Remove module cache/markers
rm -f /data/adb/falcon_seeded_v310 2>/dev/null
rm -f /data/adb/.falcon_kb_backup.xml 2>/dev/null

echo "=== CLEAN DONE ==="
echo "Now: reboot, then install FALCONINTEGITY_FIX_V3.22.zip fresh."
echo "=== END ==="