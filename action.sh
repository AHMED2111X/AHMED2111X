#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX - AUTOMATIC PIF FINGERPRINT UPDATER
# Developer: ABUFARID | Telegram: @FALCON_KERNEL
# ==============================================================================

# Ensure execution context & permissions
chmod 755 "$0" 2>/dev/null || true
if [ -f "$(dirname "$0")/sepolicy.rule" ]; then
    magisk policy --live --file "$(dirname "$0")/sepolicy.rule" 2>/dev/null || true
fi

# Ensure not running in busybox ash standalone shell
set +o standalone
unset ASH_STANDALONE

# --- Arguments Parsing ---
FORCE_TOP=1
FORCE_DEPTH=1
FORCE_STRONG=0
FORCE_MATCH=0
PATCH_COMMENT=0
spoofProvider=""
ARGS=""

until [ -z "$1" ]; do
  case "$1" in
    -h|--help|help) 
      echo "Usage: sh action.sh [-a|-s] [-m] [-t #] [-d #]"
      exit 0
      ;;
    -a|--advanced|advanced) 
      ARGS="-a"
      shift
      ;;
    -s|--strong|strong) 
      ARGS="-a"
      PATCH_COMMENT=1
      spoofProvider=0
      shift
      ;;
    -m|--match|match) 
      FORCE_MATCH=1
      shift
      ;;
    -t|--top|top) 
      echo "$2" | grep -q '^[1-9]$' || exit 1
      FORCE_TOP=$2
      shift 2
      ;;
    -d|--depth|depth) 
      echo "$2" | grep -q '^[1-9]$' || exit 1
      FORCE_DEPTH=$2
      shift 2
      ;;
    *) break;;
  esac
done

# --- Dynamic Typing & UI Functions ---
draw_banner() {
    clear
    printf "====================================================\n"
    sleep 0.1
    printf "   🦅 FALCON INTEGRITY FIX - AUTO PIF UPDATER 🦅   \n"
    sleep 0.1
    printf "====================================================\n"
    sleep 0.1
    printf "   Developer: ABUFARID | Telegram: @FALCON_KERNEL\n"
    sleep 0.1
    printf "----------------------------------------------------\n\n"
    sleep 0.1
}

step_item() { 
    printf "[➜] %s\n" "$1"
    sleep 0.1
}

step_success() { 
    printf "[✔] %s\n\n" "$1"
    sleep 0.1
}

step_info() { 
    printf "    ↳ %s\n" "$1"
    sleep 0.1
}

die() { 
    printf "\n[✖] ERROR: %s!\n\n" "$1"
    exit 1
}

die_bb() { die "$1, please install busybox"; }

# --- Permissions & Environment Checks ---
draw_banner

if [ "$USER" != "root" -a "$(whoami 2>/dev/null)" != "root" ]; then
    die "Root permissions required"
fi

case "$HOME" in
    *termux*) die "Need root environment (Run in Manager)" ;;
esac

case "$0" in
  *.sh) DIR="$0";;
  *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*action.sh$')";;
esac
DIR=$(dirname "$(readlink -f "$DIR")")

MOD_BASE="/data/adb/modules/falcon_integrity_fix"
MODDIR="$DIR"
if [ -d "$MOD_BASE" ]; then
    MODDIR="$MOD_BASE"
fi

find_busybox() {
  [ -n "$BUSYBOX" ] && return 0
  local path
  for path in /data/adb/modules/busybox-ndk/system/*/busybox /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
    if [ -f "$path" ]; then
      BUSYBOX="$path"
      return 0
    fi
  done
  return 1
}

if which wget2 >/dev/null; then
  wget() { wget2 "$@"; }
elif ! which wget >/dev/null || grep -q "wget-curl" $(which wget); then
  if ! find_busybox; then
    die_bb "wget not found"
  elif $BUSYBOX ping -c1 -s2 android.com 2>&1 | grep -q "bad address"; then
    die_bb "wget broken"
  else
    wget() { $BUSYBOX wget "$@"; }
  fi
fi

if date -D '%s' -d "$(date '+%s')" 2>&1 | grep -qE "bad date|invalid option"; then
  if ! find_busybox; then
    die_bb "date command broken"
  else
    date() { $BUSYBOX date "$@"; }
  fi
fi

if ! echo -e "A\nB" | grep -m1 -A1 "A" | grep -q "B"; then
  if ! find_busybox; then
    die_bb "grep command broken"
  else
    grep() { $BUSYBOX grep "$@"; }
  fi
fi

TEMP_DIR="/dev/falcon_pif_tmp"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || die "Failed to create working directory"

# --- Main Logic ---

step_item "Crawling Android Developers for latest Pixel Beta..."
wget -q -O PIXEL_VERSIONS_HTML --no-check-certificate "https://developer.android.com/about/versions" 2>&1 || die "Network connection error"
wget -q -O PIXEL_LATEST_HTML --no-check-certificate "$(grep -o 'https://developer.android.com/about/versions/.*[0-9]"' PIXEL_VERSIONS_HTML | sort -ru | cut -d\" -f1 | head -n$FORCE_TOP | tail -n1)" 2>&1 || die "Failed to fetch latest version HTML"
wget -q -O PIXEL_OTA_HTML --no-check-certificate "https://developer.android.com$(grep -o 'href=".*download-ota.*"' PIXEL_LATEST_HTML | grep 'qpr' | cut -d\" -f2 | head -n$FORCE_DEPTH | tail -n1)" 2>&1 || die "Failed to fetch OTA download page"

MODEL_LIST="$(grep -A1 'tr id=' PIXEL_OTA_HTML 2>/dev/null | grep 'td' | sed 's;.*<td>\(.*\)</td>.*;\1;')"
PRODUCT_LIST="$(grep -o 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\/ -f2)"
OTA_LIST="$(grep 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\" -f2)"

if [ "$FORCE_MATCH" = "1" ]; then
  DEVICE="$(getprop ro.product.device)"
  case "$PRODUCT_LIST" in
    *${DEVICE}_beta*)
      MODEL="$(getprop ro.product.model)"
      PRODUCT="${DEVICE}_beta"
      OTA="$(echo "$OTA_LIST" | grep "$PRODUCT")"
    ;;
  esac
fi

step_item "Selecting target Pixel Beta model..."
if [ -z "$PRODUCT" ]; then
  set_random_beta() {
    local list_count="$(echo "$MODEL_LIST" | wc -l)"
    local list_rand="$((RANDOM % $list_count + 1))"
    local IFS=$'\n'
    set -- $MODEL_LIST
    MODEL="$(eval echo \${$list_rand})"
    set -- $PRODUCT_LIST
    PRODUCT="$(eval echo \${$list_rand})"
    set -- $OTA_LIST
    OTA="$(eval echo \${$list_rand})"
    DEVICE="$(echo "$PRODUCT" | sed 's/_beta//')"
  }
  set_random_beta
fi

BETA_REL_DATE="$(date -D '%B %e, %Y' -d "$(grep -m1 -A1 'Release date' PIXEL_OTA_HTML | tail -n1 | sed 's;.*<td>\(.*\)</td>.*;\1;')" '+%Y-%m-%d')"
BETA_EXP_DATE="$(date -D '%s' -d "$(($(date -D '%Y-%m-%d' -d "$BETA_REL_DATE" '+%s') + 60 * 60 * 24 * 7 * 6))" '+%Y-%m-%d')"

step_info "Target Model  : $MODEL"
step_info "Target Product: $PRODUCT"
step_success "Random Beta target acquired"

step_item "Fetching Pixel OTA Zip Metadata parameters..."
(ulimit -f 2; wget -q -O PIXEL_ZIP_METADATA --no-check-certificate "$OTA") 2>/dev/null
FINGERPRINT="$(grep -am1 'post-build=' PIXEL_ZIP_METADATA 2>/dev/null | cut -d= -f2)"
SECURITY_PATCH="$(grep -am1 'security-patch-level=' PIXEL_ZIP_METADATA 2>/dev/null | cut -d= -f2)"

[ -z "$FINGERPRINT" -o -z "$SECURITY_PATCH" ] && die "Failed to extract build info from OTA metadata"

step_info "Fingerprint  : $FINGERPRINT"
step_info "Patch Level  : $SECURITY_PATCH"
step_success "OTA parameters extracted"

step_item "Writing base configuration to pif.json..."
cat <<EOF > pif.json
{
  "MANUFACTURER": "Google",
  "MODEL": "$MODEL",
  "FINGERPRINT": "$FINGERPRINT",
  "PRODUCT": "$PRODUCT",
  "DEVICE": "$DEVICE",
  "SECURITY_PATCH": "$SECURITY_PATCH",
  "DEVICE_INITIAL_SDK_INT": "32"
}
EOF
step_success "Base pif.json created"

# --- Migration & Processing ---
MIGRATE_SCRIPT=""
for m in "$MODDIR/migrate.sh" "$DIR/migrate.sh"; do
  if [ -f "$m" ]; then
    MIGRATE_SCRIPT="$m"
    break
  fi
done

if [ -n "$MIGRATE_SCRIPT" ]; then
  step_item "Converting to custom.pif.json via migrate.sh..."
  OLDJSON="$MODDIR/custom.pif.json"
  if [ -f "$OLDJSON" ]; then
    grep -q '//"\*.security_patch"' "$OLDJSON" && PATCH_COMMENT=1
    grep -qE "verboseLogs|VERBOSE_LOGS" "$OLDJSON" && ARGS="-a"
  fi
  [ -f /data/adb/tricky_store/security_patch.txt ] && unset PATCH_COMMENT

  rm -f custom.pif.json
  sh "$MIGRATE_SCRIPT" -i $ARGS pif.json >/dev/null 2>&1
  
  if [ -n "$ARGS" ]; then
    grep_json() { [ -f "$2" ] && grep -m1 "$1" "$2" | cut -d\" -f4; }
    verboseLogs=$(grep_json "VERBOSE_LOGS" "$OLDJSON")
    ADVSETTINGS="spoofBuild spoofProps spoofProvider spoofSignature spoofVendingSdk verboseLogs"
    for SETTING in $ADVSETTINGS; do
      eval [ -z \"\$$SETTING\" ] \&\& $SETTING=$(grep_json "$SETTING" "$OLDJSON")
      eval TMPVAL=\$$SETTING
      [ -n "$TMPVAL" ] && sed -i "s;\($SETTING\": \"\).;\1$TMPVAL;" custom.pif.json
    done
  fi
  
  [ "$PATCH_COMMENT" = "1" ] && sed -i 's;"\*.security_patch";//"\*.security_patch";' custom.pif.json
  sed -i "s;};\n  // Beta Released: $BETA_REL_DATE\n  // Estimated Expiry: $BETA_EXP_DATE\n};" custom.pif.json

  if [ -f "custom.pif.json" ]; then
    cp -f custom.pif.json "$MODDIR/custom.pif.json" 2>/dev/null
    cp -f custom.pif.json /data/adb/pif.json 2>/dev/null
  fi
  step_success "Custom PIF properties migrated successfully"
else
  cp -f pif.json "$MODDIR/pif.json" 2>/dev/null
  cp -f pif.json /data/adb/pif.json 2>/dev/null
  step_success "Standard pif.json deployed"
fi

# --- Tricky Store Synchronization ---
TS_SECPAT="/data/adb/tricky_store/security_patch.txt"
if [ -f "$TS_SECPAT" ]; then
  step_item "Synchronizing Tricky Store security_patch.txt..."
  [ -s "$TS_SECPAT" ] || echo "all=" > "$TS_SECPAT"
  grep -qE '^[0-9]{8}$' "$TS_SECPAT" && sed -i "s/^.*$/${SECURITY_PATCH//-}/" "$TS_SECPAT"
  grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$TS_SECPAT" && sed -i "s/^.*$/$SECURITY_PATCH/" "$TS_SECPAT"
  grep -q 'all=' "$TS_SECPAT" && sed -i "s/all=.*/all=$SECURITY_PATCH/" "$TS_SECPAT"
  grep -q 'system=' "$TS_SECPAT" && sed -i "s/system=.*/system=$(echo ${SECURITY_PATCH//-} | cut -c-6)/" "$TS_SECPAT"
  sed -i '$a\' "$TS_SECPAT"
  step_success "Tricky Store security patch aligned"
fi

# --- Process Reset ---
step_item "Resetting Google Play Services (GMS)..."
if [ -f "$MODDIR/killpi.sh" ]; then
  sh "$MODDIR/killpi.sh" >/dev/null 2>&1
else
  killall -9 com.google.android.gms.unstable com.android.vending 2>/dev/null
fi
step_success "GMS process restarted"

# --- Cleanup Workspace ---
step_item "Cleaning temporary workspace..."
cd /
rm -rf "$TEMP_DIR"
step_success "Cleanup complete"

# --- Final Summary ---
printf "====================================================\n"
sleep 0.1
printf "     ✔ SUCCESS! FINGERPRINT UPDATED SUCCESSFULLY    \n"
sleep 0.1
printf "====================================================\n"
sleep 0.1
printf "  • Device Model    : %s\n" "$MODEL"
sleep 0.1
printf "  • Fingerprint     : %s\n" "$FINGERPRINT"
sleep 0.1
printf "  • Security Patch  : %s\n" "$SECURITY_PATCH"
sleep 0.1
printf "----------------------------------------------------\n"
sleep 0.1
printf "  Developer: ABUFARID | Telegram: @FALCON_KERNEL\n"
sleep 0.1
printf "====================================================\n\n"

# Delay dialog auto-close for KernelSU / APatch
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && [ "$KSU_NEXT" != "true" ] && [ "$MMRL" != "true" ]; then
  printf "Closing dialog in 5 seconds ...\n"
  sleep 5
fi