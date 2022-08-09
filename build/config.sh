#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  echo "This script cannot be executed directly. Run build.sh instead."
  exit 1
fi

export RESCUE_RESULT_DIR="."
export RESCUE_PRODUCT_NAME="Rescue"
export RESCUE_SYSTEM_DIR="rescue"
export RESCUE_WORKDIR=$(mktemp -d)
export RESCUE_OUTPUT_NAME="rescue.iso"
export RESCUE_ISOLINUX_LEGACY_TEMPLATE="templates/isolinux.legacy.tmpl"
export RESCUE_GRUB_UEFI_TEMPLATE="templates/grub.uefi.tmpl"
export RESCUE_GRUB_EMBED_TEMPLATE="templates/grub.embed.tmpl"