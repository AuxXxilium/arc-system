# Define paths
PART1_PATH="/mnt/p1"
PART2_PATH="/mnt/p2"
PART3_PATH="/mnt/p3"
TMP_PATH="/tmp"

if [ -f "${PART1_PATH}/ARC-BRANCH" ]; then
  ARC_BRANCH=$(cat "${PART1_PATH}/ARC-BRANCH")
fi
if [ -f "${PART1_PATH}/ARC-BASE-VERSION" ]; then
  ARC_BASE_VERSION=$(cat "${PART1_PATH}/ARC-BASE-VERSION")
fi
if [ -f "${PART1_PATH}/ARC-VERSION" ]; then
  ARC_VERSION=$(cat "${PART1_PATH}/ARC-VERSION")
fi
ARC_TITLE="Arc ${ARC_VERSION}"

RAMDISK_PATH="${TMP_PATH}/ramdisk"
LOG_FILE="${TMP_PATH}/log.txt"
TMP_UP_PATH="${TMP_PATH}/upload"

USER_GRUB_CONFIG="${PART1_PATH}/boot/grub/grub.cfg"
USER_GRUBENVFILE="${PART1_PATH}/boot/grub/grubenv"
USER_CONFIG_FILE="${PART1_PATH}/user-config.yml"
GRUB_PATH="${PART1_PATH}/boot/grub"

ORI_ZIMAGE_FILE="${PART2_PATH}/zImage"
ORI_RDGZ_FILE="${PART2_PATH}/rd.gz"
ARC_BZIMAGE_FILE="${PART3_PATH}/bzImage-arc"
ARC_RAMDISK_FILE="${PART3_PATH}/initrd-arc"
MOD_ZIMAGE_FILE="${PART3_PATH}/zImage-dsm"
MOD_RDGZ_FILE="${PART3_PATH}/initrd-dsm"

SYSTEM_PATH="${PART3_PATH}/system"
ADDONS_PATH="${PART3_PATH}/addons"
MODULES_PATH="${PART3_PATH}/modules"
MODEL_CONFIG_PATH="${PART3_PATH}/configs"
PATCH_PATH="${PART3_PATH}/patches"
LKMS_PATH="${PART3_PATH}/lkms"
CUSTOM_PATH="${PART3_PATH}/custom"
USER_UP_PATH="${PART3_PATH}/users"
UNTAR_PAT_PATH="${PART3_PATH}/DSM"

S_FILE="${MODEL_CONFIG_PATH}/serials.yml"
S_FILE_ARC="${MODEL_CONFIG_PATH}/arc_serials.yml"
S_FILE_ENC="${MODEL_CONFIG_PATH}/arc_serials.enc"
S_FILE_CHECK="${MODEL_CONFIG_PATH}/arc_serials.checksum"
P_FILE="${MODEL_CONFIG_PATH}/platforms.yml"

EXTRACTOR_PATH="${PART3_PATH}/extractor"
EXTRACTOR_BIN="syno_extract_system_patch"