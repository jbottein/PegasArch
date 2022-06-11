pa_conf="${SCRIPTPATH:-.}/../config.txt"
columm_id=1
columm_scraper=2
columm_core=3
columm_path=4
columm_cloud=4

function echo.red(){
  echo -e "\e[1;31m$*"
}

function echo.green(){
  echo -e "\e[1;32m$*"
}

function get_conf(){
  grep -v "^#" "$pa_conf" | grep "|" | grep -Ei "^ *$1 *\|"
}

function get_all_ids(){
  grep -v "^#" "$pa_conf" | grep "|" | cut -d '|' -f 1 | trim
}

function get_ids_to_sync(){
  grep -v "^#" "$pa_conf" | grep -Ei "\| *sync *\|" | cut -d '|' -f $columm_id | trim
}

function get_ids_to_mount(){
  grep -v "^#" "$pa_conf" | grep -Ei "\| *mount *\|" | cut -d '|' -f $columm_id | trim
}

function get_field(){
  local var="$(get_conf "$1"  | cut -d '|' -f "$2" | trim)"
  eval echo $var
}

function get_scraper(){
  get_field "$1" $columm_scraper
}

function get_path(){
  get_field "$1" $columm_path
}

function get_core(){
  get_field "$1" $columm_core
}

function trim(){
  while read -r data; do
    echo "$data" | sed 's/ *$//g' | sed 's/^ *//g'
  done
}

function rcloneSync(){
  local FOLDER="$1"
  mkdir -p "$CLOUDDIR/$FOLDER"
  echo rclone sync "$CLOUD:$FOLDER" "$CLOUDDIR/$FOLDER"
  rclone sync "$CLOUD:$FOLDER" "$CLOUDDIR/$FOLDER"
}

function rclone_bisync(){
  local FOLDER="$1"
  local RESYNC=""
  if [[ ! -d "$CLOUDDIR/$FOLDER" ]] ; then
      mkdir -p "$CLOUDDIR/$FOLDER"
      RESYNC="--resync"
  fi
  echo rclone bisync "$CLOUD:$FOLDER" "$CLOUDDIR/$FOLDER" $RESYNC
  rclone bisync "$CLOUD:$FOLDER" "$CLOUDDIR/$FOLDER" $RESYNC
}

function rclone_mount(){
  local FOLDER="$1"
  local OPTIONS="--allow-other --read-only --vfs-cache-mode writes --allow-root --daemon-timeout=10s --daemon"
  mkdir -p "$CLOUDDIR/$FOLDER"
  echo rclone mount "$CLOUD:$FOLDER" "$CLOUDDIR/$FOLDER" $OPTIONS
  rclone mount "$CLOUD:$FOLDER" "$CLOUDDIR/$FOLDER" $OPTIONS
}


function find_core_file(){
  local core="$1"
  local file

  file="$HOME/.config/retroarch/cores/${core}_libretro.so"
  if [[ -f $file ]] ; then
    echo $file
    return
  fi

  file="$HOME/.var/app/org.libretro.RetroArch/config/retroarch/cores/${core}_libretro.so"
  if [[ -f $file ]] ; then
    echo $file
    return
  fi

  file="/usr/lib/libretro/${core}_libretro.so"
  if [[ -f $file ]] ; then
    echo $file
    return
  fi

  file=$(dpkg -L libretro-$core 2>/dev/null | grep ${core}_libretro.so | head -1)
  if [[ -f $file ]] ; then
    echo $file
    return
  fi
}


function get_or_install_core_sub(){
  local id="$1"
  local core

  core="$(get_core "$id")"
  if [[ -z $core ]] ; then
    echo "[ERROR] No core found for $1"
    return 1
  fi

  core_file="$(find_core_file "$core")"
  if [[ ! -f $core_file ]] ; then
    sudo apt-get --assume-yes install libretro-$core
    core_file="$(find_core_file "$core")"
  fi

  echo ${core_file:-${core}}
}


function get_or_install_core(){
  get_or_install_core_sub "$1" | tail -1
}
