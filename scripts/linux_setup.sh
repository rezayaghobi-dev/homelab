#!/bin/bash
#
# Linux Environment Setup Script
# Designed for: Debian-based, CentOS, and Fedora distributions
# Purpose: Prepare a newly installed Linux system for development work
# Features: Idempotent, comprehensive checks, safe execution
#

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script constants
SCRIPT_VERSION="1.0.0"
LOG_FILE="${LOG_FILE:-/tmp/linux_setup_$(date +%Y%m%d_%H%M%S).log}"

# =============================================================================
# FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    # Defaults so these are always defined under `set -u`, regardless of
    # which detection branch below ends up firing.
    DISTRO_ID="unknown"
    DISTRO_ID_LIKE=""
    DISTRO_NAME="Unknown"
    DISTRO_VERSION=""

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
        DISTRO_NAME="${NAME:-Unknown Linux}"
        DISTRO_VERSION="${VERSION_ID:-}"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO_ID="rhel"
        DISTRO_NAME="Red Hat-based"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO_ID="debian"
        DISTRO_NAME="Debian-based"
    fi

    # Determine distro family
    if [[ "$DISTRO_ID" == "ubuntu" ]] || [[ "$DISTRO_ID" == "debian" ]] || [[ "$DISTRO_ID_LIKE" == *"debian"* ]]; then
        DISTRO_FAMILY="debian"
    elif [[ "$DISTRO_ID" == "fedora" ]] || [[ "$DISTRO_ID" == "rhel" ]] || [[ "$DISTRO_ID" == "centos" ]] || [[ "$DISTRO_ID_LIKE" == *"rhel"* ]] || [[ "$DISTRO_ID_LIKE" == *"fedora"* ]]; then
        DISTRO_FAMILY="rhel"
    else
        DISTRO_FAMILY="unknown"
    fi

    log_info "Detected distribution: $DISTRO_NAME ($DISTRO_ID - $DISTRO_FAMILY family)"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if package is installed (different methods per distro)
is_package_installed() {
    local package_name="$1"
    
    case "$DISTRO_FAMILY" in
        debian)
            dpkg -l "$package_name" 2>/dev/null | grep -q "^ii"
            ;;
        rhel)
            rpm -q "$package_name" &>/dev/null
            ;;
        *)
            command_exists "$package_name"
            ;;
    esac
}

# Update package cache
update_package_cache() {
    log_info "Updating package cache..."
    
    case "$DISTRO_FAMILY" in
        debian)
            apt-get update -qq
            ;;
        rhel)
            if command_exists dnf; then
                dnf makecache -qq
            else
                yum makecache fast -qq
            fi
            ;;
        *)
            log_warning "Unknown distro family, skipping cache update"
            ;;
    esac
    
    log_success "Package cache updated"
}

# Install package(s) with retry logic
install_packages() {
    local packages=("$@")
    local failed=()
    
    for pkg in "${packages[@]}"; do
        if is_package_installed "$pkg"; then
            log_info "Package '$pkg' is already installed, skipping"
            continue
        fi
        
        log_info "Installing package: $pkg"
        
        case "$DISTRO_FAMILY" in
            debian)
                apt-get install -y -qq "$pkg" || failed+=("$pkg")
                ;;
            rhel)
                if command_exists dnf; then
                    dnf install -y -q "$pkg" || failed+=("$pkg")
                else
                    yum install -y -q "$pkg" || failed+=("$pkg")
                fi
                ;;
            *)
                log_warning "Cannot install '$pkg': Unknown distro family"
                failed+=("$pkg")
                ;;
        esac
        
        # Verify installation
        if is_package_installed "$pkg"; then
            log_success "Package '$pkg' installed successfully"
        else
            log_error "Failed to install package: $pkg"
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install: ${failed[*]}"
        return 1
    fi
    
    return 0
}

# =============================================================================
# SETUP FUNCTIONS
# =============================================================================

# Setup essential system packages
setup_essential_packages() {
    log_info "Setting up essential system packages..."
    
    local essential_packages=(
        "curl"
        "wget"
        "git"
        "vim"
        "htop"
        "jq"
        "tar"
        "gzip"
        "unzip"
        "build-essential"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "software-properties-common"
    )
    
    # Add distro-specific packages
    case "$DISTRO_FAMILY" in
        debian)
            # Ubuntu/Debian specific
            ;;
        rhel)
            # CentOS/Fedora specific - drop build-essential (Debian-only package)
            # and use the RHEL/Fedora equivalents instead.
            local filtered_packages=()
            for p in "${essential_packages[@]}"; do
                [[ "$p" == "build-essential" ]] && continue
                filtered_packages+=("$p")
            done
            essential_packages=("${filtered_packages[@]}")
            essential_packages+=("gcc" "gcc-c++" "make")
            ;;
    esac
    
    install_packages "${essential_packages[@]}"
}

# Setup Python
setup_python() {
    log_info "Setting up Python..."
    
    # Check if Python 3 is already installed
    if command_exists python3; then
        local python_version
        python_version=$(python3 --version 2>&1 | awk '{print $2}')
        log_info "Python3 is already installed (version: $python_version)"
    else
        log_info "Installing Python3..."
        case "$DISTRO_FAMILY" in
            debian)
                install_packages "python3" "python3-pip" "python3-venv"
                ;;
            rhel)
                install_packages "python3" "python3-pip"
                ;;
        esac
    fi
    
    # Verify Python installation
    if command_exists python3; then
        log_success "Python3 installed: $(python3 --version)"
    else
        log_error "Python3 installation failed"
        return 1
    fi
    
    # Upgrade pip if needed
    if command_exists python3; then
        log_info "Upgrading pip..."
        python3 -m pip install --upgrade pip --quiet 2>/dev/null || true
        log_success "pip upgraded"
    fi
    
    # Install common Python packages
    local python_packages=("virtualenv" "pipenv")
    for pkg in "${python_packages[@]}"; do
        if python3 -c "import ${pkg%:*}" 2>/dev/null; then
            log_info "Python package '$pkg' already installed"
        else
            log_info "Installing Python package: $pkg"
            python3 -m pip install "$pkg" --quiet 2>/dev/null || true
        fi
    done
    
    log_success "Python setup complete"
}

# Setup SSH
setup_ssh() {
    log_info "Setting up SSH..."
    
    # Install OpenSSH if not present
    if ! command_exists ssh; then
        log_info "Installing OpenSSH..."
        case "$DISTRO_FAMILY" in
            debian)
                install_packages "openssh-client" "openssh-server"
                ;;
            rhel)
                install_packages "openssh-clients" "openssh-server"
                ;;
        esac
    else
        log_info "OpenSSH is already installed"
    fi
    
    # Check if SSH service is available
    if command_exists systemctl; then
        # Enable SSH service
        if systemctl list-unit-files | grep -q sshd.service; then
            log_info "SSH service unit found"
            
            # Check if SSH service is enabled
            if systemctl is-enabled sshd &>/dev/null; then
                log_info "SSH service is already enabled"
            else
                log_info "Enabling SSH service..."
                systemctl enable sshd 2>/dev/null || true
            fi
            
            # Start SSH service if not running
            if systemctl is-active --quiet sshd; then
                log_info "SSH service is already running"
            else
                log_info "Starting SSH service..."
                systemctl start sshd 2>/dev/null || true
            fi
        else
            log_warning "SSH service unit not found"
        fi
    fi
    
    # Setup SSH directory and permissions
    local ssh_dir="/root/.ssh"
    if [[ "$SUDO_USER" ]]; then
        ssh_dir="/home/$SUDO_USER/.ssh"
    fi
    
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    log_success "SSH directory configured: $ssh_dir"
    
    log_success "SSH setup complete"
}

# Generate SSH key
setup_ssh_key() {
    log_info "Setting up SSH keys..."
    
    local ssh_dir="/root/.ssh"
    local key_type="ed25519"
    # Keep this filename fixed (no per-user suffix): `whoami` is always "root"
    # while this script runs under sudo, so a "$(whoami)" suffix never
    # reflected the invoking user anyway - and print_summary() looks for
    # this exact unsuffixed name when it displays the key at the end.
    local key_name="id_ed25519"
    
    if [[ "$SUDO_USER" ]]; then
        ssh_dir="/home/$SUDO_USER/.ssh"
    fi
    
    # Ensure SSH directory exists with correct permissions
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    local key_path="$ssh_dir/$key_name"
    local key_pub="$key_path.pub"
    
    # Check if key already exists
    if [[ -f "$key_path" ]]; then
        log_info "SSH key already exists at: $key_path"
        
        # Verify key permissions
        if [[ "$(stat -c %a "$key_path")" != "600" ]]; then
            log_warning "Fixing SSH key permissions..."
            chmod 600 "$key_path"
        fi
    else
        log_info "Generating new SSH key: $key_type"
        
        # Generate SSH key
        ssh-keygen -t "$key_type" -f "$key_path" -C "$(whoami)@$(hostname)-$(date +%Y%m%d)" -N ""
        
        # Set correct permissions
        chmod 600 "$key_path"
        chmod 644 "$key_pub"
        
        log_success "SSH key generated: $key_path"
    fi
    
    # Verify permissions
    chmod 600 "$key_path"
    chmod 644 "$key_pub"
    
    # Display public key
    if [[ -f "$key_pub" ]]; then
        log_info "Public key content:"
        echo "---"
        cat "$key_pub"
        echo "---"
    fi
    
    # Set ownership
    if [[ "$SUDO_USER" ]]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$ssh_dir"
    fi
    
    log_success "SSH key setup complete"
}

# Setup Docker
setup_docker() {
    log_info "Setting up Docker..."
    
    # Check if Docker is already installed
    if command_exists docker; then
        local docker_version
        docker_version=$(docker --version 2>&1)
        log_info "Docker is already installed: $docker_version"
        
        # Check if Docker service is running
        if command_exists systemctl; then
            if systemctl is-active --quiet docker; then
                log_info "Docker service is running"
            else
                log_warning "Docker installed but not running, attempting to start..."
                systemctl start docker 2>/dev/null || true
                systemctl enable docker 2>/dev/null || true
            fi
        fi
        
        log_success "Docker already configured"
        return 0
    fi
    
    log_info "Installing Docker..."
    
    case "$DISTRO_FAMILY" in
        debian)
            # Install prerequisites
            install_packages "apt-transport-https" "ca-certificates" "curl" "gnupg" "lsb-release"
            
            # Add Docker GPG key
            mkdir -p /etc/apt/keyrings
            curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
            
            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO_ID} $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Update and install
            apt-get update -qq
            install_packages "docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin"
            ;;
            
        rhel)
            if [[ "$DISTRO_ID" == "fedora" ]]; then
                # Fedora
                dnf install -y dnf-plugins-core || true
                dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo || true
                dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
                    || log_error "Docker package installation failed"
            else
                # CentOS/RHEL
                yum install -y yum-utils || true
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
                yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
                    || log_error "Docker package installation failed"
            fi
            ;;
    esac
    
    # Configure Docker service
    if command_exists systemctl; then
        log_info "Configuring Docker service..."
        
        # Enable Docker
        systemctl enable docker 2>/dev/null || true
        
        # Start Docker
        systemctl start docker 2>/dev/null || true
        
        # Add user to docker group
        if [[ "$SUDO_USER" ]] && [[ "$DISTRO_FAMILY" == "debian" ]]; then
            if ! getent group docker | grep -q "$SUDO_USER"; then
                usermod -aG docker "$SUDO_USER"
                log_info "User '$SUDO_USER' added to docker group"
            fi
        fi
    fi
    
    # Verify Docker installation
    if command_exists docker; then
        log_success "Docker installed: $(docker --version)"
        
        # Test Docker
        if docker run --rm hello-world &>/dev/null; then
            log_success "Docker is working correctly"
        else
            log_warning "Docker installed but 'hello-world' test failed"
        fi
    else
        log_error "Docker installation failed"
        return 1
    fi
    
    log_success "Docker setup complete"
}

# Setup common development tools
setup_dev_tools() {
    log_info "Setting up development tools..."
    
    local dev_tools=()
    
    case "$DISTRO_FAMILY" in
        debian)
            dev_tools=(
                "git"
                "tree"
                "net-tools"
                "iputils-ping"
                "ncdu"
                "btop" # or htop
            )
            ;;
        rhel)
            dev_tools=(
                "git"
                "tree"
                "net-tools"
                "iputils"
                "ncdu"
                "btop"
            )
            ;;
    esac
    
    install_packages "${dev_tools[@]}"
    
    log_success "Development tools setup complete"
}

# Configure system settings
configure_system() {
    log_info "Configuring system settings..."
    
    # Set timezone (if not set)
    if [[ ! -L /etc/localtime ]]; then
        log_info "Setting timezone to UTC..."
        ln -sf /usr/share/zoneinfo/UTC /etc/localtime 2>/dev/null || true
    fi
    
    # Configure shell
    if command_exists bash && [[ -f /etc/bash.bashrc ]]; then
        # Add helpful bash aliases if not present
        if ! grep -q "# User defined aliases" /etc/bash.bashrc; then
            echo "" >> /etc/bash.bashrc
            echo "# User defined aliases" >> /etc/bash.bashrc
            echo "alias ll='ls -lah'" >> /etc/bash.bashrc
            echo "alias la='ls -A'" >> /etc/bash.bashrc
            echo "alias l='ls -CF'" >> /etc/bash.bashrc
            log_info "Added shell aliases"
        fi
    fi
    
    # Configure firewall (if available)
    if command_exists ufw; then
        log_info "Configuring UFW firewall..."
        # Allow SSH *before* enabling, so a remote/SSH session doesn't get
        # locked out the moment the firewall comes up.
        ufw allow OpenSSH 2>/dev/null || ufw allow 22/tcp 2>/dev/null || true
        ufw default deny incoming 2>/dev/null || true
        ufw default allow outgoing 2>/dev/null || true
        ufw --force enable 2>/dev/null || true
        log_info "UFW firewall configured (deny incoming except SSH, allow outgoing)"
    elif command_exists firewall-cmd; then
        log_info "Configuring firewalld..."
        firewall-cmd --permanent --add-service=ssh 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        log_info "firewalld configured"
    fi
    
    log_success "System configuration complete"
}

# Print summary
print_summary() {
    echo ""
    echo "=============================================="
    echo "  Linux Setup Complete!"
    echo "=============================================="
    echo ""
    echo "Installed/Configured:"
    echo "  - Essential system packages"
    echo "  - Python 3 with pip"
    echo "  - OpenSSH server and client"
    echo "  - SSH key: ~/.ssh/id_ed25519"
    echo "  - Docker CE"
    echo "  - Development tools"
    echo ""
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Show SSH public key for easy copying
    local ssh_dir="/root/.ssh"
    if [[ "$SUDO_USER" ]]; then
        ssh_dir="/home/$SUDO_USER/.ssh"
    fi
    
    if [[ -f "$ssh_dir/id_ed25519.pub" ]]; then
        echo "Your SSH public key (add to GitHub/GitLab/etc.):"
        echo "---"
        cat "$ssh_dir/id_ed25519.pub"
        echo "---"
        echo ""
    fi
    
    if [[ -f "$ssh_dir/id_ed25519" ]]; then
        echo "To use SSH key, run:"
        echo "  eval \"\$(ssh-agent -s)\""
        echo "  ssh-add $ssh_dir/id_ed25519"
        echo ""
    fi
    
    echo "=============================================="
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Linux Environment Setup Script v${SCRIPT_VERSION}

OPTIONS:
    -h, --help              Show this help message
    --skip-packages         Skip package installation
    --skip-python           Skip Python installation
    --skip-ssh              Skip SSH installation
    --skip-ssh-key          Skip SSH key generation
    --skip-docker           Skip Docker installation
    --skip-dev-tools        Skip development tools
    --skip-system           Skip system configuration
    --log-file FILE         Custom log file path

EXAMPLES:
    $0                      # Run full setup
    $0 --skip-docker        # Setup without Docker
    $0 --log-file /tmp/mylog.log

EOF
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

main() {
    # Parse arguments
    SKIP_PACKAGES=false
    SKIP_PYTHON=false
    SKIP_SSH=false
    SKIP_SSH_KEY=false
    SKIP_DOCKER=false
    SKIP_DEV_TOOLS=false
    SKIP_SYSTEM=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --skip-python)
                SKIP_PYTHON=true
                shift
                ;;
            --skip-ssh)
                SKIP_SSH=true
                shift
                ;;
            --skip-ssh-key)
                SKIP_SSH_KEY=true
                shift
                ;;
            --skip-docker)
                SKIP_DOCKER=true
                shift
                ;;
            --skip-dev-tools)
                SKIP_DEV_TOOLS=true
                shift
                ;;
            --skip-system)
                SKIP_SYSTEM=true
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Print header
    echo ""
    echo "=============================================="
    echo "  Linux Environment Setup Script v${SCRIPT_VERSION}"
    echo "=============================================="
    echo ""
    mkdir -p "$(dirname "$LOG_FILE")"
    log_info "Log file: $LOG_FILE"
    
    # Initial checks
    check_root
    detect_distro
    
    # Check for supported distribution
    if [[ "$DISTRO_FAMILY" == "unknown" ]]; then
        log_warning "Unsupported distribution. Script may not work correctly."
        log_warning "Proceeding anyway..."
    fi
    
    # Update package cache
    if [[ "$SKIP_PACKAGES" == "false" ]]; then
        update_package_cache
    fi
    
    # Setup essential packages
    if [[ "$SKIP_PACKAGES" == "false" ]]; then
        setup_essential_packages || log_warning "Some packages may have failed to install"
    fi
    
    # Setup Python
    if [[ "$SKIP_PYTHON" == "false" ]]; then
        setup_python || log_warning "Python setup had issues"
    fi
    
    # Setup SSH
    if [[ "$SKIP_SSH" == "false" ]]; then
        setup_ssh || log_warning "SSH setup had issues"
    fi
    
    # Setup SSH Key
    if [[ "$SKIP_SSH_KEY" == "false" ]]; then
        setup_ssh_key || log_warning "SSH key setup had issues"
    fi
    
    # Setup Docker
    if [[ "$SKIP_DOCKER" == "false" ]]; then
        setup_docker || log_warning "Docker setup had issues"
    fi
    
    # Setup Development Tools
    if [[ "$SKIP_DEV_TOOLS" == "false" ]]; then
        setup_dev_tools || log_warning "Dev tools setup had issues"
    fi
    
    # Configure System
    if [[ "$SKIP_SYSTEM" == "false" ]]; then
        configure_system || log_warning "System configuration had issues"
    fi
    
    # Print summary
    print_summary
    
    log_success "All tasks completed!"
}

# Run main function
main "$@"