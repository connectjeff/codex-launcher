#!/bin/zsh
# Configuration Manager for Codex Launcher
# Handles profiles, export/import, and configuration editing

set -euo pipefail

CONFIG_DIR="${HOME}/codex-config/codex-home-lmstudio"
PREF_FILE="${CONFIG_DIR}/launcher-preferences.toml"
PROFILES_DIR="${HOME}/codex-config/profiles"

# Initialize profiles directory
init_profiles() {
    mkdir -p "${PROFILES_DIR}"
}

# List all saved profiles
list_profiles() {
    init_profiles
    if [[ -z "$(ls -A "${PROFILES_DIR}" 2>/dev/null)" ]]; then
        echo "No profiles found. Create one with: ./config-manager.sh create <name>"
        return 1
    fi
    
    echo "Available profiles:"
    for file in "${PROFILES_DIR}"/*.toml; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file" .toml)
            echo "  - ${name}"
        fi
    done
}

# Create a new profile from current config
create_profile() {
    local name="$1"
    if [[ -z "${name}" ]]; then
        echo "Usage: ./config-manager.sh create <profile_name>"
        exit 1
    fi
    
    init_profiles
    
    local profile_file="${PROFILES_DIR}/${name}.toml"
    
    # Copy current config to profile
    if [[ -f "${CONFIG_DIR}/config.toml" ]]; then
        cp "${CONFIG_DIR}/config.toml" "${profile_file}"
        echo "Created profile: ${name}"
        
        # Save last-used model in profile
        local current_model=$(grep "model = " "${CONFIG_DIR}/config.toml" 2>/dev/null | cut -d'"' -f2 || echo "")
        if [[ -n "${current_model}" ]]; then
            save_preference "last_used_model" "${current_model}"
        fi
    else
        echo "Error: No config.toml found. Launch Codex with Local LM Studio mode first."
        exit 1
    fi
}

# Switch to a different profile
switch_profile() {
    local name="$1"
    if [[ -z "${name}" ]]; then
        echo "Usage: ./config-manager.sh switch <profile_name>"
        exit 1
    fi
    
    local profile_file="${PROFILES_DIR}/${name}.toml"
    
    if [[ ! -f "${profile_file}" ]]; then
        echo "Error: Profile '${name}' not found."
        list_profiles
        exit 1
    fi
    
    # Backup current config before switching
    if [[ -f "${CONFIG_DIR}/config.toml" ]]; then
        cp "${CONFIG_DIR}/config.toml" "${CONFIG_DIR}/config.toml.backup"
    fi
    
    # Copy profile to current config
    cp "${profile_file}" "${CONFIG_DIR}/config.toml"
    
    echo "Switched to profile: ${name}"
}

# Export current configuration
export_config() {
    local output_file="${1:-${HOME}/Desktop/codex-config-export.tar.gz}"
    
    if [[ ! -f "${CONFIG_DIR}/config.toml" ]]; then
        echo "Error: No config.toml found."
        exit 1
    fi
    
    # Create export directory if needed
    mkdir -p "$(dirname "${output_file}")"
    
    # Export config and preferences
    tar -czf "${output_file}" -C "${CONFIG_DIR}" config.toml launcher-preferences.toml 2>/dev/null || {
        # If tar fails, try alternate method
        cp "${CONFIG_DIR}/config.toml" "${output_file}.config.toml"
        [[ -f "${PREF_FILE}" ]] && cp "${PREF_FILE}" "${output_file}.preferences.toml"
    }
    
    echo "Configuration exported to: ${output_file}"
}

# Import configuration from backup
import_config() {
    local input_file="${1}"
    if [[ -z "${input_file}" ]]; then
        echo "Usage: ./config-manager.sh import <file>"
        exit 1
    fi
    
    if [[ ! -f "${input_file}" ]]; then
        echo "Error: File not found: ${input_file}"
        exit 1
    fi
    
    # Backup current config before importing
    if [[ -f "${CONFIG_DIR}/config.toml" ]]; then
        cp "${CONFIG_DIR}/config.toml" "${CONFIG_DIR}/config.toml.backup-before-import"
    fi
    
    # Extract tar.gz
    if [[ "${input_file}" == *.tar.gz ]]; then
        mkdir -p "${CONFIG_DIR}"
        tar -xzf "${input_file}" -C "${CONFIG_DIR}" 2>/dev/null || {
            echo "Error: Failed to extract tar.gz file"
            exit 1
        }
    else
        # Plain file - copy to config.toml
        cp "${input_file}" "${CONFIG_DIR}/config.toml"
    fi
    
    echo "Configuration imported from: ${input_file}"
}

# Save preference to launcher preferences file
save_preference() {
    local key="$1"
    local value="$2"
    
    mkdir -p "$(dirname "${PREF_FILE}")"
    
    if [[ -f "${PREF_FILE}" ]]; then
        # Remove existing key if present
        grep -v "^${key} = " "${PREF_FILE}" > "${PREF_FILE}.tmp" || true
        mv "${PREF_FILE}.tmp" "${PREF_FILE}"
    fi
    
    echo "${key} = \"${value}\"" >> "${PREF_FILE}"
}

# Display current configuration
show_config() {
    echo "Current Configuration:"
    echo "====================="
    
    if [[ -f "${CONFIG_DIR}/config.toml" ]]; then
        echo "Config file: ${CONFIG_DIR}/config.toml"
        grep -v "^#" "${CONFIG_DIR}/config.toml" | grep -v "^$" || echo "(empty or all comments)"
    else
        echo "Config file: NOT FOUND"
    fi
    
    if [[ -f "${PREF_FILE}" ]]; then
        echo ""
        echo "Launcher Preferences:"
        cat "${PREF_FILE}"
    fi
    
    if [[ -d "${PROFILES_DIR}" ]]; then
        echo ""
        echo "Available Profiles:"
        ls -1 "${PROFILES_DIR}"/*.toml 2>/dev/null | while read file; do
            echo "  - $(basename "$file" .toml)"
        done || echo "  (none)"
    fi
}

# Edit configuration in editor
edit_config() {
    local editor="${EDITOR:-vi}"
    
    if [[ ! -f "${CONFIG_DIR}/config.toml" ]]; then
        echo "No config.toml found. Creating new one..."
        mkdir -p "${CONFIG_DIR}"
        cat > "${CONFIG_DIR}/config.toml" <<'EOF'
# Codex Configuration
model = "qwen/qwen3-coder-next"
model_provider = "lmstudio-local"

[chat_view]
show_timestamps = true
EOF
    fi
    
    "${editor}" "${CONFIG_DIR}/config.toml"
}

# Main command handler
main() {
    local cmd="${1:-}"
    shift || true
    
    case "${cmd}" in
        list|ls)
            list_profiles
            ;;
        create|new)
            create_profile "$@"
            ;;
        switch|use)
            switch_profile "$@"
            ;;
        export|backup)
            export_config "$@"
            ;;
        import|restore)
            import_config "$@"
            ;;
        show|info|status)
            show_config
            ;;
        edit|open|nano|vim|vi)
            edit_config "$@"
            ;;
        *)
            echo "Codex Configuration Manager"
            echo ""
            echo "Usage: $0 <command> [args]"
            echo ""
            echo "Commands:"
            echo "  list              List all saved profiles"
            echo "  create <name>     Create a new profile from current config"
            echo "  switch <name>     Switch to a different profile"
            echo "  export [file]     Export current configuration"
            echo "  import <file>     Import configuration from backup"
            echo "  show              Display current configuration"
            echo "  edit              Edit configuration in text editor"
            echo ""
            exit 1
            ;;
    esac
}

main "$@"
