#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX - AUTOMATIC PIF FINGERPRINT UPDATER
# Developer: ABUFARID | Telegram: @FALCON_KERNEL
# ==============================================================================

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
    die "Root permissions required";
fi

case "$HOME" in
    *termux*) die "Need root environment (Run in Manager)";;
esac

until [ -z "$1" ]; do
  case "$1" in
    -h|--help|help) echo "sh action.sh [-a|-s] [-m]"; exit 0;;
    -a|--advanced|advanced) ARGS="-a"; shift;;
    -s|--strong|strong) FORCE_STRONG=1; shift;;
    -m|--match|match) FORCE_MATCH=1; shift;;
    *) break;;
  esac
done

case "$0" in
  *.sh) DIR="$0";;
  *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*action.sh$')";;
esac
DIR=$(dirname "$(readlink -f "$DIR")")

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

if ! which wget >/dev/null || grep -q "wget-curl" $(which wget); then
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

TEMP_DIR="/dev/playintegrityfix_tmp"
mkdir -p $TEMP_DIR
cd "$TEMP_DIR"

# --- Main Logic ---

step_item "Crawling Google Android Developers for latest Pixel Beta..."
wget -q -O PIXEL_VERSIONS_HTML --no-check-certificate "https://developer.android.com/about/versions" 2>&1 || die "Network connection error"
wget -q -O PIXEL_LATEST_HTML --no-check-certificate "$(grep -o 'https://developer.android.com/about/versions/.*[0-9]"' PIXEL_VERSIONS_HTML | sort -ru | cut -d\" -f1 | head -n1 | tail -n1)" 2>&1 || die "Failed to fetch latest version HTML"
wget -q -O PIXEL_FI_HTML --no-check-certificate "https://developer.android.com$(grep -o 'href=".*download.*"' PIXEL_LATEST_HTML | grep 'qpr' | cut -d\" -f2 | head -n1 | tail -n1)" 2>&1 || die "Failed to fetch download page"

MODEL_LIST="$(grep -A1 'tr id=' PIXEL_FI_HTML 2>/dev/null | grep 'td' | sed 's;.*<td>\(.*\)</td>.*;\1;')"
PRODUCT_LIST="$(grep 'tr id=' PIXEL_FI_HTML 2>/dev/null | sed 's;.*<tr id="\(.*\)">.*;\1_beta;')"
step_success "Html data parsed successfully"

step_item "Selecting target Pixel Beta model..."
set_random_beta() {
  local list_count="$(echo "$MODEL_LIST" | wc -l)"
  local list_rand="$((RANDOM % $list_count + 1))"
  local IFS=$'\n'
  set -- $MODEL_LIST
  MODEL="$(eval echo \${$list_rand})"
  set -- $PRODUCT_LIST
  PRODUCT="$(eval echo \${$list_rand})"
  DEVICE="$(echo "$PRODUCT" | sed 's/_beta//')"
}
set_random_beta
step_info "Target Model  : $MODEL"
step_info "Target Product: $PRODUCT"
step_success "Random Beta target acquired"

step_item "Fetching latest Pixel Canary build parameters..."
wget -q -O PIXEL_FLASH_HTML --no-check-certificate "https://flash.android.com/" 2>&1 || die "Failed to connect to flash.android.com"
FLASH_KEY="$(grep -o '<body data-client-config=.*' PIXEL_FLASH_HTML | cut -d\; -f2 | cut -d\& -f1)"
wget -q -O PIXEL_STATION_JSON --header "Referer: https://flash.android.com" --no-check-certificate "https://content-flashstation-pa.googleapis.com/v1/builds?product=$PRODUCT&key=$FLASH_KEY" 2>&1 || die "Failed to fetch builds JSON"
tac PIXEL_STATION_JSON | grep -m1 -A13 '"canary": true' > PIXEL_CANARY_JSON

ID="$(grep 'releaseCandidateName' PIXEL_CANARY_JSON 2>/dev/null | cut -d\" -f4)"
INCREMENTAL="$(grep 'buildId' PIXEL_CANARY_JSON 2>/dev/null | cut -d\" -f4)"
[ -z "$ID" -o -z "$INCREMENTAL" ] && die "Failed to extract build info from Google JSON"
step_info "Build ID     : $ID"
step_info "Incremental  : $INCREMENTAL"
step_success "Canary parameters extracted"

step_item "Resolving Security Patch level..."
CANARY_ID="$(grep '"id"' PIXEL_CANARY_JSON | sed -e 's;.*canary-\(.*\)".*;\1;' -e 's;^\(.\{4\}\);\1-;')"
wget -q -O PIXEL_SECBULL_HTML --no-check-certificate "https://source.android.com/docs/security/bulletin/pixel" 2>&1

SECURITY_PATCH="$(grep "<td>$CANARY_ID" PIXEL_SECBULL_HTML 2>/dev/null | sed 's;.*<td>\(.*\)</td>;\1;')"
if [ -z "$SECURITY_PATCH" ]; then
  SECURITY_PATCH="${CANARY_ID}-05"
fi
step_info "Patch Level  : $SECURITY_PATCH"
step_success "Security Patch resolved"

FINGERPRINT="google/$PRODUCT/$DEVICE:CANARY/$ID/$INCREMENTAL:user/release-keys"

step_item "Writing configuration to /data/adb/pif.json..."
cat <<EOF > /data/adb/pif.json
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
step_success "Configuration injected"

step_item "Resetting Google Play Services (GMS)..."
killall -9 com.google.android.gms.unstable 2>/dev/null
step_success "GMS process restarted"

step_item "Cleaning temporary workspace..."
rm -rf $TEMP_DIR
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