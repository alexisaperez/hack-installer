#/bin/bash
clear
function dl_resources {
  if [ ! -f '/tmp/EFI-X299-10.13-Final-Release-280917.zip' ]; then
    curl https://www.tonymacx86.com/attachments/efi-x299-10-13-final-release-280917-zip.281498/?temp_hash=9a4f7a513c0e630ab31cb3731094ca9c -o /tmp/EFI-X299-10.13-Final-Release-280917.zip
  fi
  if [ ! -f '/tmp/VoodooTSCSync.kext.zip' ]; then
    curl https://www.tonymacx86.com/attachments/voodootscsync-kext-zip.277142/?temp_hash=934f3d395c8a98d708e517af57ece9cf -o /tmp/VoodooTSCSync.kext.zip
  fi
}
function create_installer {
  '/Applications/Install macOS High Sierra.app/Contents/Resources/createinstallmedia' --volume '/Volumes/USB' --applicationpath '/Applications/Install macOS High Sierra.app' --no interaction
}
function list_externals {
  external_disks=($(diskutil list | grep ".*external*" | sed -e 's/ (external, physical)://g'))
  echo "Select external disk: "
     select selected_external in ${external_disks[@]}; do
         echo "You selected $selected_external"
         set_disk=$selected_external
         break
     done
}
function prep_install_fs {
  if [ $vv_sel == "installer" ]; then
    diskutil unmountDisk "${set_disk}"
    diskutil eraseDisk JHFS+ 'USB' "${set_disk}"
    diskutil mount $(diskutil list | grep "Apple_HFS USB" | grep -o "disk.*")
  else
    diskutil unmountDisk "${set_disk}"
    diskutil eraseDisk JHFS+ 'Hackintosh HD' "${set_disk}"
    diskutil mount $(diskutil list | grep "Apple_HFS Hackintosh HD" | grep -o "disk.*")
  fi
}
function toggle_baseSystem {
  # Mount installer to copy apfs.efi
  if [ "${1}" == 'attach' ]; then
    hdiutil attach -noverify '/Applications/Install macOS High Sierra.app/Contents/SharedSupport/BaseSystem.dmg' &> /dev/null
  else
    hdiutil detach $(diskutil list | grep "Apple_HFS OS X Base System" | grep -o "disk.*") &> /dev/null
  fi
}

function copy_efi {
  # Installer Disk
  diskutil mount "${set_disk}"s1
  unzip /tmp/EFI-X299-10.13-Final-Release-280917.zip 'EFI-X299-10.13-Final-Release-280917/EFI/*' -d /Volumes/EFI/ &> /dev/null
  mv /Volumes/EFI/EFI-X299-10.13-Final-Release-280917/EFI/ /Volumes/EFI/
  cp '/Volumes/OS X Base System/usr/standalone/i386/apfs.efi' '/Volumes/EFI/EFI/CLOVER/drivers64UEFI/apfs.efi'
  unzip /tmp/VoodooTSCSync.kext.zip -d '/Volumes/EFI/EFI/CLOVER/kexts/10.12/' &> /dev/null
  rm -rf /Volumes/EFI/EFI/CLOVER/kexts/Other/KGP-ASUSPrimeX299Deluxe-USB.kext
  rm -rf /Volumes/EFI/EFI-X299-10.13-Final-Release-280917/
}

function clean_installer_disk {
  rm -rf /Volumes/EFI/EFI/CLOVER/drivers64UEFI/EmuVariableUefi-64.efi
}
function start_installer_disk {
  dl_resources
  list_externals
  prep_install_fs
  create_installer
  copy_efi
  clean_installer_disk

}
function start_system_disk {
  dl_resources
  list_externals
  prep_install_fs
  copy_efi
}

function main_menu {
  clear
  toggle_baseSystem "attach"
  echo 'Please select from the menu: '
  options=("Prep Installer Disk" "Prep System Disk" "Quit")
  select vv in "${options[@]}"
  do
      case $vv in
          "Prep Installer Disk")
              echo "Creating Installer disk..."
              vv_sel="installer"
              start_installer_disk
              main_menu
              ;;
          "Prep System Disk")
              echo "Creating System disk"
              vv_sel="system"
              start_system_disk
              main_menu
              ;;
          "Quit")
              if [ -d /Volumes/EFI/ ]; then
                diskutil unmount /Volumes/EFI/
              fi
              if [ -d /Volumes/USB/ ]; then
                diskutil unmount /Volumes/USB/
              fi
              toggle_baseSystem "detach"
              exit
              ;;
          *) echo invalid option;;
      esac
  done

}
main_menu
