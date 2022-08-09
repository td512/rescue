#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
  then echo "[*] This script must be run as root."
  exit 1
fi

SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
pushd "${SCRIPTPATH}"

. ./config.sh

if [ "$(grep -Ei 'debian|buntu' /etc/*release)" ]; then
   echo "[+] Running prerequisite check..."
else
  echo "[-] Skipping prerequisite check (not Debian/Ubuntu)"
fi

mkdir -p $RESCUE_WORKDIR/{staging/{EFI/BOOT,boot/grub/x86_64-efi,isolinux,live},tmp}

echo "[+] Generating squashfs"
mksquashfs \
    $RESCUE_SYSTEM_DIR \
    $RESCUE_WORKDIR/staging/live/filesystem.squashfs \
    -e boot

echo "[+] Copying kernel" && \
cp $RESCUE_SYSTEM_DIR/boot/vmlinuz-* \
    $RESCUE_WORKDIR/staging/live/vmlinuz && \
echo "[+] Copying initrd" && \
cp $RESCUE_SYSTEM_DIR/boot/initrd.img-* \
    $RESCUE_WORKDIR/staging/live/initrd

echo "[+] Creating ISOLINUX config"
cp $RESCUE_ISOLINUX_LEGACY_TEMPLATE $RESCUE_WORKDIR/staging/isolinux/isolinux.cfg
sed -i -e "s/@@PRODUCTNAME@@/$RESCUE_PRODUCT_NAME/g" $RESCUE_WORKDIR/staging/isolinux/isolinux.cfg

echo "[+] Creating GRUB config"
cp $RESCUE_GRUB_UEFI_TEMPLATE $RESCUE_WORKDIR/staging/boot/grub/grub.cfg
sed -i -e "s/@@PRODUCTNAME@@/$RESCUE_PRODUCT_NAME/g" $RESCUE_WORKDIR/staging/boot/grub/grub.cfg

cp $RESCUE_WORKDIR/staging/boot/grub/grub.cfg $RESCUE_WORKDIR/staging/EFI/BOOT/

echo "[+] Creating GRUB embed config"
cp $RESCUE_GRUB_EMBED_TEMPLATE $RESCUE_WORKDIR/tmp/grub-embed.cfg

echo "[+] Copying ISOLINUX files"
cp /usr/lib/ISOLINUX/isolinux.bin "${RESCUE_WORKDIR}/staging/isolinux/" && \
cp /usr/lib/syslinux/modules/bios/* "${RESCUE_WORKDIR}/staging/isolinux/"

echo "[+] Copying GRUB files"
cp -r /usr/lib/grub/x86_64-efi/* "${RESCUE_WORKDIR}/staging/boot/grub/x86_64-efi/"

echo "[+] Generating EFI images"
echo "[+] i386"
grub-mkstandalone -O i386-efi \
    --modules="part_gpt part_msdos fat iso9660" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="$RESCUE_WORKDIR/staging/EFI/BOOT/BOOTIA32.EFI" \
    "boot/grub/grub.cfg=$RESCUE_WORKDIR/tmp/grub-embed.cfg"

echo "[+] amd64"
grub-mkstandalone -O x86_64-efi \
    --modules="part_gpt part_msdos fat iso9660" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="$RESCUE_WORKDIR/staging/EFI/BOOT/BOOTx64.EFI" \
    "boot/grub/grub.cfg=$RESCUE_WORKDIR/tmp/grub-embed.cfg"

echo "[+] Creating EFI disk"
(cd $RESCUE_WORKDIR/staging && \
    dd if=/dev/zero of=efiboot.img bs=1M count=20 && \
    mkfs.vfat efiboot.img && \
    mmd -i efiboot.img ::/EFI ::/EFI/BOOT && \
    mcopy -vi efiboot.img \
        $RESCUE_WORKDIR/staging/EFI/BOOT/BOOTIA32.EFI \
        $RESCUE_WORKDIR/staging/EFI/BOOT/BOOTx64.EFI \
        $RESCUE_WORKDIR/staging/boot/grub/grub.cfg \
        ::/EFI/BOOT/
)

echo "[+] Creating ISO ${RESCUE_RESULT_DIR}/${RESCUE_OUTPUT_NAME}"
popd
xorriso \
    -as mkisofs \
    -iso-level 3 \
    -o "${RESCUE_RESULT_DIR}/${RESCUE_OUTPUT_NAME}" \
    -full-iso9660-filenames \
    -volid "DEBLIVE" \
    --mbr-force-bootable -partition_offset 16 \
    -joliet -joliet-long -rational-rock \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-boot \
        isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog isolinux/isolinux.cat \
    -eltorito-alt-boot \
        -e --interval:appended_partition_2:all:: \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
    -append_partition 2 0xef ${RESCUE_WORKDIR}/staging/efiboot.img \
    "${RESCUE_WORKDIR}/staging"

echo "[*] Cleaning up"
rm -rf $RESCUE_WORKDIR