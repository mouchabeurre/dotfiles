# Find where asdf should be installed
ASDF_INSTALL_DIR="/opt/asdf-vm"

# Load command
if [[ -f "${ASDF_INSTALL_DIR}/asdf.sh" ]]; then
    . "${ASDF_INSTALL_DIR}/asdf.sh"
fi

