###############################################################################
# Update Loader
function updateLoader() {
  local TAG="${1}"
  if [ -z "${TAG}" ]; then
    idx=0
    while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
      local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-loader/releases" | jq -r ".[].tag_name" | grep -v "dev" | sort -rV | head -1)"
      if [ -n "${TAG}" ]; then
        break
      fi
      sleep 3
      idx=$((${idx} + 1))
    done
  fi
  if [ -n "${TAG}" ]; then
    (
      echo "Downloading ${TAG}"
      local URL="https://github.com/AuxXxilium/arc/releases/download/${TAG}/update-${TAG}.zip"
      curl -#kL "${URL}" -o "${TMP_PATH}/update.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/update.zip" ]; then
        echo -e "Downloading Base Image successful!\nUpdating Base Image..."
        if unzip -oq "${TMP_PATH}/update.zip" -d "${PART3_PATH}"; then
          echo "${TAG}" > "${PART1_PATH}/ARC-BASE-VERSION"
          echo "Successful!"
          sleep 2
        else
          updateFailed
        fi
      else
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "System" \
      --progressbox "Installing Base Image..." 20 70
  fi
  return 0
}

###############################################################################
# Update System
function updateSystem() {
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-system/releases" | jq -r ".[].tag_name" | grep -v "dev" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ]; then
    (
      local URL="https://github.com/AuxXxilium/arc-system/releases/download/${TAG}/system-${TAG}.zip"
      echo "Downloading ${TAG}"
      curl -#kL "${URL}" -o "${TMP_PATH}/system.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/system.zip" ]; then
        mkdir -p "${SYSTEM_PATH}"
        echo "Installing new System..."
        if unzip -oq "${TMP_PATH}/system.zip" -d "${PART3_PATH}"; then
          rm -f "${TMP_PATH}/system.zip"
          echo "${TAG}" > "${PART1_PATH}/ARC-VERSION"
          echo "Successful!"
        else
          updateFailed
        fi
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "System" \
      --progressbox "Installing System Update..." 20 70
  fi
  return 0
}

###############################################################################
# Update Addons
function updateAddons() {
  [ -f "${ADDONS_PATH}/VERSION" ] && local ADDONSVERSION="$(cat "${ADDONS_PATH}/VERSION")" || ADDONSVERSION="0.0.0"
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-addons/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ] && [ "${ADDONSVERSION}" != "${TAG}" ]; then
    (
      echo "Downloading ${TAG}"
      local URL="https://github.com/AuxXxilium/arc-addons/releases/download/${TAG}/addons.zip"
      curl -#kL "${URL}" -o "${TMP_PATH}/addons.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/addons.zip" ]; then
        rm -rf "${ADDONS_PATH}"
        mkdir -p "${ADDONS_PATH}"
        echo "Installing new Addons..."
        if unzip -oq "${TMP_PATH}/addons.zip" -d "${ADDONS_PATH}"; then
          rm -f "${TMP_PATH}/addons.zip"
          for F in $(ls ${ADDONS_PATH}/*.addon 2>/dev/null); do
            ADDON=$(basename "${F}" | sed 's|.addon||')
            rm -rf "${ADDONS_PATH}/${ADDON}"
            mkdir -p "${ADDONS_PATH}/${ADDON}"
            tar -xaf "${F}" -C "${ADDONS_PATH}/${ADDON}"
            rm -f "${F}"
          done
          echo "Successful!"
        else
          updateFailed
        fi
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Addons" \
      --progressbox "Installing Addons..." 20 70
  fi
  return 0
}

###############################################################################
# Update Patches
function updatePatches() {
  [ -f "${PATCH_PATH}/VERSION" ] && local PATCHESVERSION="$(cat "${PATCH_PATH}/VERSION")" || PATCHESVERSION="0.0.0"
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-patches/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ] && [ "${PATCHESVERSION}" != "${TAG}" ]; then
    (
      local URL="https://github.com/AuxXxilium/arc-patches/releases/download/${TAG}/patches.zip"
      echo "Downloading ${TAG}"
      curl -#kL "${URL}" -o "${TMP_PATH}/patches.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/patches.zip" ]; then
        rm -rf "${PATCH_PATH}"
        mkdir -p "${PATCH_PATH}"
        echo "Installing new Patches..."
        if unzip -oq "${TMP_PATH}/patches.zip" -d "${PATCH_PATH}"; then
          rm -f "${TMP_PATH}/patches.zip"
          echo "Successful!"
        else
          updateFailed
        fi
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Patches" \
      --progressbox "Installing Patches..." 20 70
  fi
  return 0
}

###############################################################################
# Update Custom
function updateCustom() {
  [ -f "${CUSTOM_PATH}/VERSION" ] && local CUSTOMVERSION="$(cat "${CUSTOM_PATH}/VERSION")" || CUSTOMVERSION="0.0.0"
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-custom/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ] && [ "${CUSTOMVERSION}" != "${TAG}" ]; then
    (
      local URL="https://github.com/AuxXxilium/arc-custom/releases/download/${TAG}/custom.zip"
      echo "Downloading ${TAG}"
      curl -#kL "${URL}" -o "${TMP_PATH}/custom.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/custom.zip" ]; then
        rm -rf "${CUSTOM_PATH}"
        mkdir -p "${CUSTOM_PATH}"
        echo "Installing new Custom Kernel..."
        if unzip -oq "${TMP_PATH}/custom.zip" -d "${CUSTOM_PATH}"; then
          rm -f "${TMP_PATH}/custom.zip"
          echo "Successful!"
        else
          updateFailed
        fi
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Custom" \
      --progressbox "Installing Custom..." 20 70
  fi
  return 0
}

###############################################################################
# Update Modules
function updateModules() {
  [ -f "${MODULES_PATH}/VERSION" ] && local MODULESVERSION="$(cat "${MODULES_PATH}/VERSION")" || MODULESVERSION="0.0.0"
  local PRODUCTVER="$(readConfigKey "productver" "${USER_CONFIG_FILE}")"
  local PLATFORM="$(readConfigKey "platform" "${USER_CONFIG_FILE}")"
  local KVER="$(readConfigKey "platforms.${PLATFORM}.productvers.\"${PRODUCTVER}\".kver" "${P_FILE}")"
  [ "${PLATFORM}" == "epyc7002" ] && KVERP="${PRODUCTVER}-${KVER}" || KVERP="${KVER}"
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-modules/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ] && [ "${MODULESVERSION}" != "${TAG}" ]; then
    (
      rm -rf "${MODULES_PATH}"
      mkdir -p "${MODULES_PATH}"
      local URL="https://github.com/AuxXxilium/arc-modules/releases/download/${TAG}/${PLATFORM}-${KVERP}.modules"
      echo "Downloading Modules ${TAG}"
      curl -#kL "${URL}" -o "${MODULES_PATH}/${PLATFORM}-${KVERP}.modules" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      echo "Downloading Firmware ${TAG}"
      local URL="https://github.com/AuxXxilium/arc-modules/releases/download/${TAG}/firmware.modules"
      curl -#kL "${URL}" -o "${MODULES_PATH}/firmware.modules" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${MODULES_PATH}/${PLATFORM}-${KVERP}.modules" ] && [ -f "${MODULES_PATH}/firmware.modules" ]; then
        echo "${TAG}" > "${MODULES_PATH}/VERSION"
        if [ -n "${PLATFORM}" ] && [ -n "${KVERP}" ]; then
          echo "Installing Modules..."
          writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
          echo "Rebuilding Modules..."
          while read -r ID DESC; do
            writeConfigKey "modules.${ID}" "" "${USER_CONFIG_FILE}"
          done < <(getAllModules "${PLATFORM}" "${KVERP}")
        fi
        echo "Successful!"
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Modules" \
      --progressbox "Installing Modules..." 20 70
  fi
  return 0
}

###############################################################################
# Update Configs
function updateConfigs() {
  local ARCKEY="$(readConfigKey "arc.key" "${USER_CONFIG_FILE}")"
  [ -f "${MODEL_CONFIGS_PATH}/VERSION" ] && local CONFIGSVERSION="$(cat "${MODEL_CONFIG_PATH}/VERSION")" || CONFIGSVERSION="0.0.0"
  if [ -z "${1}" ]; then
    idx=0
    while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
      local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-configs/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
      if [ -n "${TAG}" ]; then
        break
      fi
      sleep 3
      idx=$((${idx} + 1))
    done
  else
    local TAG="${1}"
  fi
  if [ -n "${TAG}" ] && [ "${CONFIGSVERSION}" != "${TAG}" ]; then
    (
      local URL="https://github.com/AuxXxilium/arc-configs/releases/download/${TAG}/configs.zip"
      echo "Downloading ${TAG}"
      curl -#kL "${URL}" -o "${TMP_PATH}/configs.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/configs.zip" ]; then
        mkdir -p "${MODEL_CONFIG_PATH}"
        echo "Installing new Configs..."
        if unzip -oq "${TMP_PATH}/configs.zip" -d "${MODEL_CONFIG_PATH}"; then
          rm -f "${TMP_PATH}/configs.zip"
          CONFHASH="$(sha256sum "${S_FILE}" | awk '{print $1}')"
          writeConfigKey "arc.confhash" "${CONFHASH}" "${USER_CONFIG_FILE}"
          echo "Successful!"
        else
          updateFailed
        fi
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Configs" \
      --progressbox "Installing Configs..." 20 70
  fi
  return 0
}

###############################################################################
# Update LKMs
function updateLKMs() {
  [ -f "${LKMS_PATH}/VERSION" ] && local LKMVERSION="$(cat "${LKMS_PATH}/VERSION")" || LKMVERSION="0.0.0"
  if [ -z "${1}" ]; then
    idx=0
    while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
      local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-lkm/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
      if [ -n "${TAG}" ]; then
        break
      fi
      sleep 3
      idx=$((${idx} + 1))
    done
  else
    local TAG="${1}"
  fi
  if [ -n "${TAG}" ] && [ "${LKMVERSION}" != "${TAG}" ]; then
    (
      local URL="https://github.com/AuxXxilium/arc-lkm/releases/download/${TAG}/rp-lkms.zip"
      echo "Downloading ${TAG}"
      curl -#kL "${URL}" -o "${TMP_PATH}/rp-lkms.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/rp-lkms.zip" ]; then
        rm -rf "${LKMS_PATH}"
        mkdir -p "${LKMS_PATH}"
        echo "Installing new LKMs..."
        if unzip -oq "${TMP_PATH}/rp-lkms.zip" -d "${LKMS_PATH}"; then
          rm -f "${TMP_PATH}/rp-lkms.zip"
          echo "Successful!"
        else
          updateFailed
        fi
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "LKMs" \
      --progressbox "Installing LKMs..." 20 70
  fi
  return 0
}

###############################################################################
# Loading Update Mode
function arcUpdate() {
  KERNEL="$(readConfigKey "kernel" "${USER_CONFIG_FILE}")"
  BUILDDONE="$(readConfigKey "arc.builddone" "${USER_CONFIG_FILE}")"
  FAILED="false"
  dialog --backtitle "$(backtitle)" --title "Update Dependencies" --aspect 18 \
    --infobox "Updating Dependencies..." 0 0
  sleep 3
  updateAddons
  [ $? -ne 0 ] && FAILED="true"
  updateModules
  [ $? -ne 0 ] && FAILED="true"
  updateLKMs
  [ $? -ne 0 ] && FAILED="true"
  updatePatches
  [ $? -ne 0 ] && FAILED="true"
  if [ "${KERNEL}" == "custom" ]; then
    updateCustom
    [ $? -ne 0 ] && FAILED="true"
  fi
  if [ "${FAILED}" == "true" ] && [ "${UPDATEMODE}" == "true" ]; then
    dialog --backtitle "$(backtitle)" --title "Update Dependencies" --aspect 18 \
      --infobox "Update failed!\nTry again later." 0 0
    sleep 3
    exec reboot
  elif [ "${FAILED}" == "true" ]; then
    dialog --backtitle "$(backtitle)" --title "Update Dependencies" --aspect 18 \
      --infobox "Update failed!\nTry again later." 0 0
    sleep 3
  elif [ "${FAILED}" == "false" ] && [ "${UPDATEMODE}" == "true" ]; then
    dialog --backtitle "$(backtitle)" --title "Update Dependencies" --aspect 18 \
      --infobox "Update successful! -> Reboot to automated build..." 0 0
    sleep 3
    rebootTo "automated"
  elif [ "${FAILED}" == "false" ]; then
    dialog --backtitle "$(backtitle)" --title "Update Dependencies" --aspect 18 \
      --infobox "Update successful!" 0 0
    writeConfigKey "arc.builddone" "false" "${USER_CONFIG_FILE}"
    BUILDDONE="$(readConfigKey "arc.builddone" "${USER_CONFIG_FILE}")"
    sleep 3
    clear
    arc.sh
  fi
}

###############################################################################
# Update Offline
function updateOffline() {
  local ARCMODE="$(readConfigKey "arc.mode" "${USER_CONFIG_FILE}")"
  if [ "${ARCMODE}" != "automated" ]; then
    rm -f "${SYSTEM_PATH}/include/offline.json"
    curl -skL "https://autoupdate.synology.com/os/v2" -o "${SYSTEM_PATH}/include/offline.json"
  fi
  return 0
}

###############################################################################
# Update Failed
function updateFailed() {
  local MODE="$(readConfigKey "arc.mode" "${USER_CONFIG_FILE}")"
  if [ "${ARCMODE}" == "automated" ]; then
    echo "Installation failed!"
    sleep 5
    exec reboot
    exit 1
  else
    echo "Installation failed!"
    return 1
  fi
}

function updateFaileddialog() {
  local MODE="$(readConfigKey "arc.mode" "${USER_CONFIG_FILE}")"
  if [ "${ARCMODE}" == "automated" ]; then
    dialog --backtitle "$(backtitle)" --title "Update Failed" \
      --infobox "Installation failed!" 0 0
    sleep 5
    exec reboot
    exit 1
  else
    dialog --backtitle "$(backtitle)" --title "Update Failed" \
      --msgbox "Installation failed!" 0 0
    return 1
  fi
}

###############################################################################
# Arc Base File download called by init.sh
function getArcBase() {
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc/releases" | jq -r ".[].tag_name" | grep -v "dev" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ]; then
    (
      echo "Downloading ${TAG}"
      local URL="https://github.com/AuxXxilium/arc/releases/download/${TAG}/update-${TAG}.zip"
      curl -#kL "${URL}" -o "${TMP_PATH}/update.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/update.zip" ]; then
        echo -e "Downloading Base Image successful!\nUpdating Base Image..."
        if unzip -oq "${TMP_PATH}/update.zip" -d "${PART3_PATH}"; then
          rm -f "${TMP_PATH}/update.zip" >/dev/null
          echo "${TAG}" > "${PART1_PATH}/ARC-BASE-VERSION"
          echo "Successful! -> Rebooting..."
          sleep 2
        else
          echo "Failed to unpack Base Image."
          return 1
        fi
      else
        echo "Failed to download Base Image."
        return 1
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "System" \
      --progressbox "Installing Base Image..." 20 70
  fi
  return 0
}

###############################################################################
# Arc System Files download called by init.sh
function getArcSystem() {
  local CACHE_FILE="/tmp/system.zip"
  rm -f "${CACHE_FILE}"
  if [ -n "${1}" ]; then
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-system/releases" | jq -r ".[].tag_name" | grep "dev" | sort -rV | head -1)"
  else
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-system/releases" | jq -r ".[].tag_name" | grep -v "dev" | sort -rV | head -1)"
  fi
  if curl -skL "https://github.com/AuxXxilium/arc-system/releases/download/${TAG}/system-${TAG}.zip" -o "${CACHE_FILE}"; then
    mkdir -p "${SYSTEM_PATH}"
    if unzip -oq "${CACHE_FILE}" -d "${PART3_PATH}" >/dev/null 2>&1; then
      echo "${TAG}" >"${PART1_PATH}/ARC-VERSION"
      [ -f "${SYSTEM_PATH}/grub.cfg" ] && cp -f "${SYSTEM_PATH}/grub.cfg" "${USER_GRUB_CONFIG}"
      rm -f "${CACHE_FILE}"
      return 0
    else
      echo -e "Failed to unpack System Image."
      return 1
    fi
  else
    echo -e "Failed to download Arc System Files. Check your network connection.\nYou can restart download with 'init.sh' command."
    return 1
  fi
}