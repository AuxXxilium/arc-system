###############################################################################
# Upgrade Loader
function upgradeLoader () {
  local ARCBRANCH="$(readConfigKey "arc.branch" "${USER_CONFIG_FILE}")"
  rm -f "${TMP_PATH}/arc.img.zip"
  if [ -z "${1}" ]; then
    # Check for new Version
    idx=0
    while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
      local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-e/releases" | jq -r ".[].tag_name" | grep -v "dev" | sort -rV | head -1)"
      if [ -n "${TAG}" ]; then
        break
      fi
      sleep 3
      idx=$((${idx} + 1))
    done
  else
    local TAG="${1}"
  fi
    (
      # Download update file
      echo "Downloading ${TAG}"
      if [ "${ARCBRANCH}" != "stable" ]; then
        local URL="https://github.com/AuxXxilium/arc-e/releases/download/${TAG}/arc-${TAG}-${ARCBRANCH}.img.zip"
      else
        local URL="https://github.com/AuxXxilium/arc-e/releases/download/${TAG}/arc-${TAG}.img.zip"
      fi
      curl -#kL "${URL}" -o "${TMP_PATH}/arc.img.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/arc.img.zip" ]; then
        echo "Downloading Base Image successful!"
      else
        updateFailed
      fi
      unzip -oq "${TMP_PATH}/arc.img.zip" -d "${TMP_PATH}"
      rm -f "${TMP_PATH}/arc.img.zip" >/dev/null
      echo "Installing new Base Image..."
      # Process complete update
      umount "${PART1_PATH}" "${PART2_PATH}" "${PART3_PATH}"
      if [ "${ARCBRANCH}" != "stable" ]; then
        if dd if="${TMP_PATH}/arc-${ARCBRANCH}.img" of=$(blkid | grep 'LABEL="ARC3"' | cut -d3 -f1) bs=1M conv=fsync; then
          rm -f "${TMP_PATH}/arc-${ARCBRANCH}.img" >/dev/null
        else
          updateFailed
        fi
      else
        if dd if="${TMP_PATH}/arc.img" of=$(blkid | grep 'LABEL="ARC3"' | cut -d3 -f1) bs=1M conv=fsync; then
          rm -f "${TMP_PATH}/arc.img" >/dev/null
        else
          updateFailed
        fi
      fi
      echo "Upgrade done! -> Rebooting..."
      deleteConfigKey "arc.confhash" "${USER_CONFIG_FILE}"
      sleep 2
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Upgrade Loader" \
      --progressbox "Upgrading Loader..." 20 70
  fi
  return 0
}

###############################################################################
# Update Loader
function updateLoader() {
  local ARCMODE="$(readConfigKey "arc.mode" "${USER_CONFIG_FILE}")"
  local ARCBRANCH="$(readConfigKey "arc.branch" "${USER_CONFIG_FILE}")"
  if [ -z "${1}" ]; then
    # Check for new Version
    idx=0
    while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
      local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-e/releases" | jq -r ".[].tag_name" | grep -v "dev" | sort -rV | head -1)"
      if [ -n "${TAG}" ]; then
        break
      fi
      sleep 3
      idx=$((${idx} + 1))
    done
  else
    local TAG="${1}"
  fi
  if [ -n "${TAG}" ]; then
    (
      # Download update file
      echo "Downloading ${TAG}"
      if [ "${ARCBRANCH}" != "stable" ]; then
        local URL="https://github.com/AuxXxilium/arc-e/releases/download/${TAG}/update-${ARCBRANCH}.zip"
      else
        local URL="https://github.com/AuxXxilium/arc-e/releases/download/${TAG}/update.zip"
      fi
      curl -#kL "${URL}" -o "${TMP_PATH}/update.zip" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/update.zip" ]; then
        echo "Installing new Base Image..."
        unzip -oq "${TMP_PATH}/update.zip" -d "${PART3_PATH}"
        mv -f "${PART3_PATH}/grub.cfg" "${USER_GRUB_CONFIG}"
        mv -f "${PART3_PATH}/ARC-BASE-VERSION" "${PART1_PATH}/ARC-BASE-VERSION"
        mv -f "${PART3_PATH}/ARC-BRANCH" "${PART1_PATH}/ARC-BRANCH"
        rm -f "${TMP_PATH}/update.zip"
        echo "Update done!"
        sleep 2
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Full-Update Loader" \
      --progressbox "Updating Loader..." 20 70
  else
    updateFaileddialog
  fi
  return 0
}

###############################################################################
# Update Addons
function updateAddons() {
  # Check for new Version
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-addons/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ]; then
    (
      # Download update file
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
        unzip -oq "${TMP_PATH}/addons.zip" -d "${ADDONS_PATH}"
        rm -f "${TMP_PATH}/addons.zip"
        for F in $(ls ${ADDONS_PATH}/*.addon 2>/dev/null); do
          ADDON=$(basename "${F}" | sed 's|.addon||')
          rm -rf "${ADDONS_PATH}/${ADDON}"
          mkdir -p "${ADDONS_PATH}/${ADDON}"
          echo "Installing ${F} to ${ADDONS_PATH}/${ADDON}"
          tar -xaf "${F}" -C "${ADDONS_PATH}/${ADDON}"
          rm -f "${F}"
        done
        echo "Update done!"
        sleep 2
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Update Addons" \
      --progressbox "Updating Addons..." 20 70
  fi
  return 0
}

###############################################################################
# Update Patches
function updatePatches() {
  # Check for new Version
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-patches/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ]; then
    (
      # Download update file
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
        unzip -oq "${TMP_PATH}/patches.zip" -d "${PATCH_PATH}"
        rm -f "${TMP_PATH}/patches.zip"
        echo "Update done!"
        sleep 2
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Update Patches" \
      --progressbox "Updating Patches..." 20 70
  fi
  return 0
}

###############################################################################
# Update Custom
function updateCustom() {
  # Check for new Version
  idx=0
  while [ ${idx} -le 5 ]; do # Loop 5 times, if successful, break
    local TAG="$(curl -m 10 -skL "https://api.github.com/repos/AuxXxilium/arc-custom/releases" | jq -r ".[].tag_name" | sort -rV | head -1)"
    if [ -n "${TAG}" ]; then
      break
    fi
    sleep 3
    idx=$((${idx} + 1))
  done
  if [ -n "${TAG}" ]; then
    (
      # Download update file
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
        unzip -oq "${TMP_PATH}/custom.zip" -d "${CUSTOM_PATH}"
        rm -f "${TMP_PATH}/custom.zip"
        echo "Update done!"
        sleep 2
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Update Custom" \
      --progressbox "Updating Custom..." 20 70
  fi
  return 0
}

###############################################################################
# Update Modules
function updateModules() {
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
  if [ -n "${TAG}" ]; then
    (
      # Download update file
      local URL="https://github.com/AuxXxilium/arc-modules/releases/download/${TAG}/${PLATFORM}-${KVERP}.modules"
      echo "Downloading ${TAG}"
      rm -f "${TMP_PATH}/*.modules"
      curl -#kL "${URL}" -o "${TMP_PATH}/${PLATFORM}-${KVERP}.modules" 2>&1 | while IFS= read -r -n1 char; do
        [[ $char =~ [0-9] ]] && keep=1 ;
        [[ $char == % ]] && echo "$progress%" && progress="" && keep=0 ;
        [[ $keep == 1 ]] && progress="$progress$char" ;
      done
      if [ -f "${TMP_PATH}/${PLATFORM}-${KVERP}.modules" ]; then
        rm -rf "${MODULES_PATH}"
        mkdir -p "${MODULES_PATH}"
        echo "Installing new Modules..."
        cp -f "${TMP_PATH}/${PLATFORM}-${KVERP}.modules" "${MODULES_PATH}/${PLATFORM}-${KVERP}.modules"
        # Rebuild modules if model/build is selected
        if [ -n "${PLATFORM}" ] && [ -n "${KVERP}" ]; then
          writeConfigKey "modules" "{}" "${USER_CONFIG_FILE}"
          echo "Rebuilding Modules..."
          while read -r ID DESC; do
            writeConfigKey "modules.${ID}" "" "${USER_CONFIG_FILE}"
          done < <(getAllModules "${PLATFORM}" "${KVERP}")
        fi
        echo "Update done!"
        sleep 2
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Update Modules" \
      --progressbox "Updating Modules..." 20 70
  fi
  return 0
}

###############################################################################
# Update Configs
function updateConfigs() {
  local ARCKEY="$(readConfigKey "arc.key" "${USER_CONFIG_FILE}")"
  if [ -z "${1}" ]; then
    # Check for new Version
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
  if [ -n "${TAG}" ]; then
    (
      # Download update file
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
        [ -n "${ARCKEY}" ] && cp -f "${S_FILE}" "${TMP_PATH}/serials.yml"
        unzip -oq "${TMP_PATH}/configs.zip" -d "${MODEL_CONFIG_PATH}"
        rm -f "${TMP_PATH}/configs.zip"
        [ -n "${ARCKEY}" ] && cp -f "${TMP_PATH}/serials.yml" "${S_FILE}"
        CONFHASH="$(sha256sum "${S_FILE}" | awk '{print $1}')"
        writeConfigKey "arc.confhash" "${CONFHASH}" "${USER_CONFIG_FILE}"
        echo "Update done!"
        sleep 2
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Update Configs" \
      --progressbox "Updating Configs..." 20 70
  fi
  return 0
}

###############################################################################
# Update LKMs
function updateLKMs() {
  if [ -z "${1}" ]; then
    # Check for new Version
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
  if [ -n "${TAG}" ]; then
    (
      # Download update file
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
        unzip -oq "${TMP_PATH}/rp-lkms.zip" -d "${LKMS_PATH}"
        rm -f "${TMP_PATH}/rp-lkms.zip"
        echo "Update done!"
        sleep 2
      else
        echo "Error downloading new Version!"
        sleep 5
        updateFailed
      fi
    ) 2>&1 | dialog --backtitle "$(backtitle)" --title "Update LKMs" \
      --progressbox "Updating LKMs..." 20 70
  fi
  return 0
}

###############################################################################
# Update Failed
function updateFailed() {
  local MODE="$(readConfigKey "arc.mode" "${USER_CONFIG_FILE}")"
  if [ "${ARCMODE}" == "automated" ]; then
    echo "Update failed!"
    sleep 5
    exec reboot
    exit 1
  else
    echo "Update failed!"
    return 1
  fi
}

function updateFaileddialog() {
  local MODE="$(readConfigKey "arc.mode" "${USER_CONFIG_FILE}")"
  if [ "${ARCMODE}" == "automated" ]; then
    dialog --backtitle "$(backtitle)" --title "Update Failed" \
      --infobox "Update failed!" 0 0
    sleep 5
    exec reboot
    exit 1
  else
    dialog --backtitle "$(backtitle)" --title "Update Failed" \
      --msgbox "Update failed!" 0 0
    return 1
  fi
}