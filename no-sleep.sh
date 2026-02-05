#!/bin/bash

################################################################################
# Ubuntu 24.04 No-Sleep Configuration Script
# Purpose: Configure system to stay awake 24/7 for RDP access
# Usage: bash no-sleep.sh [--no-root] [--stop]
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script variables
SCRIPT_DIR="$HOME"
KEEPAWAKE_PID_FILE="$HOME/.keep_awake.pid"
LOG_FILE="$HOME/no-sleep-install.log"

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; }

# Function to check if running with root privileges
check_root() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to stop all sleep prevention
stop_sleep_prevention() {
    print_info "Stopping all sleep prevention measures..."
    
    # Stop keep-awake script
    if [ -f "$KEEPAWAKE_PID_FILE" ]; then
        if [ -s "$KEEPAWAKE_PID_FILE" ]; then
            PID=$(cat "$KEEPAWAKE_PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                kill "$PID" 2>/dev/null && print_success "Stopped keep-awake daemon (PID: $PID)"
            else
                print_warning "Keep-awake daemon not running"
            fi
        fi
        rm -f "$KEEPAWAKE_PID_FILE"
    fi
    
    # Kill any running keep-awake processes
    pkill -f "keep.*awake" 2>/dev/null && print_success "Killed keep-awake processes"
    
    if check_root; then
        print_info "Re-enabling sleep targets (requires root)..."
        systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null
        print_success "Sleep targets re-enabled"
        
        if [ -f /etc/systemd/logind.conf.d/no-sleep.conf ]; then
            rm -f /etc/systemd/logind.conf.d/no-sleep.conf
            systemctl restart systemd-logind
            print_success "Removed logind no-sleep configuration"
        fi
    fi
    
    print_success "Sleep prevention stopped"
    exit 0
}

# Parse command line arguments
NO_ROOT_MODE=false
for arg in "$@"; do
    case $arg in
        --no-root)
            NO_ROOT_MODE=true
            shift
            ;;
        --stop)
            stop_sleep_prevention
            ;;
        --help|-h)
            echo "Usage: $0 [--no-root] [--stop]"
            echo ""
            echo "Options:"
            echo "  --no-root    Run without requiring root privileges (limited functionality)"
            echo "  --stop       Stop all sleep prevention measures"
            echo "  --help       Show this help message"
            exit 0
            ;;
    esac
done

################################################################################
# Main Script Start
################################################################################

echo ""
echo "================================================================================"
echo "           Ubuntu 24.04 - No Sleep Configuration Script"
echo "           Keep Your System Awake 24/7 for RDP Access"
echo "================================================================================"
echo ""
date | tee "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check root privileges
HAS_ROOT=false
if check_root; then
    HAS_ROOT=true
    print_success "Running with root privileges - full configuration available"
elif [ "$NO_ROOT_MODE" = false ]; then
    print_warning "Not running as root - some features will be limited"
    print_info "Run with 'sudo' for full configuration, or use '--no-root' flag"
    echo ""
    read -p "Continue without root? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Exiting. Run with: sudo bash $0"
        exit 1
    fi
    NO_ROOT_MODE=true
fi

echo ""

################################################################################
# Step 1: Kill Light Locker
################################################################################
print_info "Step 1: Disabling Light Locker..."

if pgrep -f light-locker > /dev/null; then
    pkill -f light-locker 2>/dev/null && print_success "Light-locker process terminated"
else
    print_info "Light-locker is not running"
fi

# Prevent light-locker from autostarting
if [ -f "$HOME/.config/autostart/light-locker.desktop" ]; then
    mv "$HOME/.config/autostart/light-locker.desktop" "$HOME/.config/autostart/light-locker.desktop.bak" 2>/dev/null
    print_success "Light-locker autostart disabled"
fi

echo ""

################################################################################
# Step 2: Configure X11 Power Management
################################################################################
print_info "Step 2: Disabling X11 screen saver and power management..."

if command -v xset &> /dev/null; then
    export DISPLAY=:0
    
    xset s off 2>/dev/null && print_success "X11 screen saver disabled"
    xset -dpms 2>/dev/null && print_success "X11 DPMS power management disabled"
    xset s noblank 2>/dev/null && print_success "X11 screen blanking disabled"
    
    # Verify settings
    if xset q 2>/dev/null | grep -q "DPMS is Disabled"; then
        print_success "Verified: DPMS is disabled"
    fi
else
    print_warning "xset command not found - X11 configuration skipped"
fi

echo ""

################################################################################
# Step 3: Mask Systemd Sleep Targets (Root Required)
################################################################################
print_info "Step 3: Masking systemd sleep targets..."

if [ "$HAS_ROOT" = true ]; then
    systemctl mask sleep.target 2>/dev/null && print_success "Masked sleep.target"
    systemctl mask suspend.target 2>/dev/null && print_success "Masked suspend.target"
    systemctl mask hibernate.target 2>/dev/null && print_success "Masked hibernate.target"
    systemctl mask hybrid-sleep.target 2>/dev/null && print_success "Masked hybrid-sleep.target"
else
    print_warning "Skipped (requires root) - sleep targets not masked"
fi

echo ""

################################################################################
# Step 4: Configure Systemd Logind (Root Required)
################################################################################
print_info "Step 4: Configuring systemd logind..."

if [ "$HAS_ROOT" = true ]; then
    mkdir -p /etc/systemd/logind.conf.d/
    
    cat > /etc/systemd/logind.conf.d/no-sleep.conf << 'EOF'
[Login]
HandlePowerKey=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
IdleActionSec=0
EOF
    
    if [ -f /etc/systemd/logind.conf.d/no-sleep.conf ]; then
        print_success "Created /etc/systemd/logind.conf.d/no-sleep.conf"
        
        systemctl restart systemd-logind 2>/dev/null && print_success "Restarted systemd-logind service"
    else
        print_error "Failed to create logind configuration"
    fi
else
    print_warning "Skipped (requires root) - logind not configured"
fi

echo ""

################################################################################
# Step 5: Install Required Packages
################################################################################
print_info "Step 5: Checking and installing required packages..."

if [ "$HAS_ROOT" = true ]; then
    # Update package list
    print_info "Updating package list..."
    apt-get update >> "$LOG_FILE" 2>&1
    
    # Install xdotool if not present
    if ! command -v xdotool &> /dev/null; then
        print_info "Installing xdotool..."
        apt-get install -y xdotool >> "$LOG_FILE" 2>&1 && print_success "Installed xdotool"
    else
        print_success "xdotool already installed"
    fi
    
    # Install xrdp if not present
    if ! command -v xrdp &> /dev/null; then
        print_info "Installing xrdp..."
        apt-get install -y xrdp >> "$LOG_FILE" 2>&1 && print_success "Installed xrdp"
        
        systemctl enable xrdp >> "$LOG_FILE" 2>&1
        systemctl start xrdp >> "$LOG_FILE" 2>&1
        print_success "xrdp service enabled and started"
    else
        print_success "xrdp already installed"
        systemctl is-active --quiet xrdp || systemctl start xrdp
    fi
    
    # Configure firewall for RDP
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            print_info "Configuring firewall for RDP..."
            ufw allow 3389/tcp >> "$LOG_FILE" 2>&1 && print_success "Firewall configured for RDP (port 3389)"
        fi
    fi
else
    print_warning "Skipped (requires root) - package installation skipped"
fi

echo ""

################################################################################
# Step 6: Create Keep-Awake Daemon
################################################################################
print_info "Step 6: Creating and starting keep-awake daemon..."

# Stop existing keep-awake daemon if running
if [ -f "$KEEPAWAKE_PID_FILE" ] && [ -s "$KEEPAWAKE_PID_FILE" ]; then
    OLD_PID=$(cat "$KEEPAWAKE_PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
        print_info "Stopped old keep-awake daemon (PID: $OLD_PID)"
    fi
fi

# Create keep-awake script
cat > "$SCRIPT_DIR/keep_awake_daemon.sh" << 'EOF'
#!/bin/bash
# Keep-awake daemon to prevent system sleep
# Simulates keyboard activity every 4 minutes

LOG_FILE="$HOME/keep_awake.log"
echo "[$(date)] Keep-awake daemon started" >> "$LOG_FILE"

while true; do
    export DISPLAY=:0
    
    # Try xdotool first (cleaner method)
    if command -v xdotool &> /dev/null; then
        xdotool key shift >> "$LOG_FILE" 2>&1
    else
        # Fallback: touch a file to show activity
        touch "$HOME/.keep_awake_heartbeat"
    fi
    
    # Log heartbeat every 30 minutes
    if [ $((SECONDS % 1800)) -eq 0 ]; then
        echo "[$(date)] Keep-awake daemon running" >> "$LOG_FILE"
    fi
    
    sleep 240  # 4 minutes
done
EOF

chmod +x "$SCRIPT_DIR/keep_awake_daemon.sh"
print_success "Created keep-awake daemon script"

# Start keep-awake daemon in background
nohup bash "$SCRIPT_DIR/keep_awake_daemon.sh" > /dev/null 2>&1 &
KEEPAWAKE_PID=$!
echo "$KEEPAWAKE_PID" > "$KEEPAWAKE_PID_FILE"
print_success "Started keep-awake daemon (PID: $KEEPAWAKE_PID)"

echo ""

################################################################################
# Step 7: Create Autostart Entry
################################################################################
print_info "Step 7: Creating autostart entry..."

mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/no-sleep.desktop" << EOF
[Desktop Entry]
Type=Application
Name=No Sleep Prevention
Comment=Keep system awake for RDP access
Exec=bash $SCRIPT_DIR/keep_awake_daemon.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Terminal=false
EOF

print_success "Created autostart entry at ~/.config/autostart/no-sleep.desktop"

echo ""

################################################################################
# Step 8: Create XSession Configuration
################################################################################
print_info "Step 8: Creating XSession configuration..."

cat > "$HOME/.xsession" << 'EOF'
#!/bin/bash
# XSession configuration to prevent sleep during RDP
xset s off
xset -dpms
xset s noblank
exec startxfce4
EOF

chmod +x "$HOME/.xsession"
print_success "Created ~/.xsession configuration"

echo ""

################################################################################
# Step 9: Disable Console Blanking
################################################################################
print_info "Step 9: Disabling console blanking..."

if [ "$HAS_ROOT" = true ]; then
    # Disable console blanking permanently
    if ! grep -q "consoleblank=0" /etc/default/grub 2>/dev/null; then
        print_info "Adding console blanking prevention to GRUB..."
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 consoleblank=0"/' /etc/default/grub
        update-grub >> "$LOG_FILE" 2>&1 && print_success "GRUB updated (reboot required for this change)"
    else
        print_info "Console blanking already disabled in GRUB"
    fi
    
    # Disable for current session
    setterm -blank 0 -powerdown 0 2>/dev/null && print_success "Console blanking disabled for current session"
else
    print_warning "Skipped (requires root) - GRUB configuration not modified"
fi

echo ""

################################################################################
# Step 10: Verify Configuration
################################################################################
print_info "Step 10: Verifying configuration..."

sleep 2

# Check if keep-awake daemon is running
if [ -f "$KEEPAWAKE_PID_FILE" ]; then
    PID=$(cat "$KEEPAWAKE_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        print_success "Keep-awake daemon is running (PID: $PID)"
    else
        print_error "Keep-awake daemon failed to start"
    fi
fi

# Check systemd targets
if [ "$HAS_ROOT" = true ]; then
    if systemctl status sleep.target 2>&1 | grep -q "masked"; then
        print_success "Sleep targets are masked"
    else
        print_warning "Sleep targets may not be properly masked"
    fi
fi

# Check xrdp service
if command -v xrdp &> /dev/null; then
    if systemctl is-active --quiet xrdp 2>/dev/null; then
        print_success "xrdp service is running"
        print_info "RDP connection available on port 3389"
    else
        print_warning "xrdp service is not running"
    fi
fi

echo ""

################################################################################
# Summary and Next Steps
################################################################################
echo "================================================================================"
echo "                          Configuration Complete!"
echo "================================================================================"
echo ""
print_success "Your system has been configured to stay awake 24/7"
echo ""
echo "Applied Configurations:"
echo "  ✓ Light-locker disabled"
echo "  ✓ X11 power management disabled"
if [ "$HAS_ROOT" = true ]; then
    echo "  ✓ Systemd sleep targets masked"
    echo "  ✓ Logind configured to ignore power events"
    echo "  ✓ xrdp installed and configured"
    echo "  ✓ Console blanking disabled"
else
    echo "  ⚠ Systemd sleep targets not masked (requires root)"
    echo "  ⚠ Logind not configured (requires root)"
fi
echo "  ✓ Keep-awake daemon running (PID: $(cat $KEEPAWAKE_PID_FILE 2>/dev/null || echo 'N/A'))"
echo "  ✓ Autostart entry created"
echo "  ✓ XSession configured"
echo ""

if [ "$HAS_ROOT" = true ]; then
    echo "Next Steps:"
    echo "  1. Your system will now stay awake 24/7"
    echo "  2. RDP is accessible on port 3389"
    echo "  3. A reboot is recommended to apply all changes"
    echo ""
    echo "To reboot now: sudo reboot"
else
    echo "For Full Configuration:"
    echo "  Run this script with root privileges:"
    echo "  sudo bash $0"
    echo ""
    echo "  This will enable:"
    echo "    - Permanent systemd sleep prevention"
    echo "    - xrdp installation and configuration"
    echo "    - GRUB console blanking prevention"
fi

echo ""
echo "Management Commands:"
echo "  • Stop sleep prevention:  bash $0 --stop"
echo "  • View keep-awake log:    cat ~/keep_awake.log"
echo "  • Installation log:       cat $LOG_FILE"
echo ""
echo "System Information:"
echo "  • IP Address: $(hostname -I | awk '{print $1}')"
echo "  • Hostname: $(hostname)"
echo "  • RDP Port: 3389"
echo ""
echo "================================================================================"
echo ""
