#!/bin/bash

# Frolf Bot Development Environment - New Developer Onboarding
# This script guides new developers through the complete setup process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}$1${NC}"
    echo "$(echo "$1" | sed 's/./=/g')"
    echo ""
}

print_step() {
    echo -e "🚀 ${CYAN}$1${NC}"
    echo ""
}

print_success() {
    echo -e "✅ ${GREEN}$1${NC}"
    echo ""
}

print_warning() {
    echo -e "⚠️  ${YELLOW}$1${NC}"
    echo ""
}

print_error() {
    echo -e "❌ ${RED}$1${NC}"
    echo ""
}

print_info() {
    echo -e "ℹ️  ${BLUE}$1${NC}"
}

# Function to ask yes/no questions
ask_yes_no() {
    while true; do
        read -p "$1 [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            return 0
        elif [[ $REPLY =~ ^[Nn]$ ]]; then
            return 1
        else
            echo "Please answer yes (y) or no (n)."
        fi
    done
}

# Function to wait for user input
wait_for_input() {
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read
}

clear

print_header "🎮 Welcome to Frolf Bot Development!"

echo "This interactive setup will guide you through:"
echo "• Installing required development tools"
echo "• Cloning all necessary repositories"
echo "• Setting up the complete development environment"
echo "• Starting your first development session"
echo ""
echo "Expected time: 10-15 minutes (depending on download speeds)"
echo ""

if ! ask_yes_no "Ready to start the setup?"; then
    echo "Setup cancelled. Run this script again when you're ready!"
    exit 0
fi

clear

# Step 1: Environment Check
print_header "📋 Step 1: Environment Check"
print_step "Let's check your current development environment..."

if [ ! -f "Tiltfile" ]; then
    print_error "You must run this script from the frolf-bot-infrastructure directory!"
    echo "Please:"
    echo "1. Navigate to the frolf-bot-infrastructure directory"
    echo "2. Run: ./scripts/onboard.sh"
    exit 1
fi

print_success "Running from the correct directory"

# Check if verification script exists
if [ -f "./scripts/verify-setup.sh" ]; then
    print_step "Running environment verification..."
    ./scripts/verify-setup.sh
    echo ""
    
    if ask_yes_no "Did the verification pass? If not, we'll help fix the issues."; then
        print_success "Great! Your environment looks good."
    else
        print_step "Let's fix the environment issues..."
        
        if ask_yes_no "Install missing development tools?"; then
            print_step "Installing development tools..."
            make install-tools
            print_success "Tools installation complete!"
        fi
    fi
else
    print_warning "Verification script not found. Continuing with setup..."
fi

wait_for_input

clear

# Step 2: Repository Setup
print_header "📂 Step 2: Repository Setup"
print_step "Now let's make sure you have all the required repositories..."

print_info "The Frolf Bot project consists of multiple repositories:"
print_info "• frolf-bot-infrastructure (this repo) - Infrastructure & deployment"
print_info "• frolf-bot - Backend API server"
print_info "• discord-frolf-bot - Discord bot application"
print_info "• frolf-bot-shared - Shared Go libraries"
echo ""

print_step "Checking current repository status..."
make check-repos
echo ""

# Count missing repos
MISSING_REPOS=0
[ ! -d "../frolf-bot" ] && ((MISSING_REPOS++))
[ ! -d "../discord-frolf-bot" ] && ((MISSING_REPOS++))
[ ! -d "../frolf-bot-shared" ] && ((MISSING_REPOS++))

if [ $MISSING_REPOS -gt 0 ]; then
    print_step "Found $MISSING_REPOS missing repositories. Let's get them set up..."
    echo ""
    
    print_info "You have several options:"
    print_info "1. 🔍 Auto-detect existing repositories in common locations"
    print_info "2. 📂 Clone repositories from remote URLs"
    print_info "3. 🔗 Manually link to existing local repositories"
    echo ""
    
    echo "Which option would you prefer?"
    echo "1) Auto-detect existing repositories"
    echo "2) Clone from remote repositories"  
    echo "3) Manually link to existing repositories"
    read -p "Enter your choice [1-3]: " -n 1 -r REPO_CHOICE
    echo ""
    echo ""
    
    case $REPO_CHOICE in
        1)
            print_step "Auto-detecting repositories in common locations..."
            if make auto-detect-repos; then
                echo ""
                if ask_yes_no "Did auto-detection find your repositories?"; then
                    print_info "Great! Please use the suggested link commands shown above."
                    print_info "After linking, you can continue with the setup."
                    wait_for_input
                else
                    print_step "No problem, let's try another approach..."
                    if ask_yes_no "Would you like to clone the repositories instead?"; then
                        print_step "Cloning repositories..."
                        make clone-repos
                    fi
                fi
            fi
            ;;
        2)
            print_step "Cloning repositories from remote URLs..."
            print_warning "⚠️  IMPORTANT: Repository URLs Configuration"
            echo "Before cloning, you need to update the repository URLs in the Makefile."
            echo "The default URLs are placeholders and need to be updated to your actual repositories."
            echo ""
            echo "Current configuration in Makefile:"
            echo "  BACKEND_REPO_URL = https://github.com/YOUR_ORG/frolf-bot.git"
            echo "  DISCORD_REPO_URL = https://github.com/YOUR_ORG/discord-frolf-bot.git"
            echo "  SHARED_REPO_URL = https://github.com/YOUR_ORG/frolf-bot-shared.git"
            echo ""
            
            if ask_yes_no "Have you updated the repository URLs in the Makefile?"; then
                print_step "Attempting to clone repositories..."
                if make clone-repos; then
                    print_success "Repositories cloned successfully!"
                else
                    print_error "Failed to clone repositories. Please check the URLs and try again."
                    echo "You can manually edit the Makefile and run 'make clone-repos' later."
                fi
            else
                print_warning "Please update the repository URLs in the Makefile first:"
                echo "1. Edit the Makefile"
                echo "2. Update the *_REPO_URL variables with your actual repository URLs"
                echo "3. Run 'make clone-repos' manually"
                echo ""
                echo "Continuing with the rest of the setup..."
            fi
            ;;
        3)
            print_step "Manual linking to existing repositories..."
            print_info "You can link to existing repositories using symlinks."
            print_info "This is useful if you already have the repositories cloned elsewhere."
            echo ""
            print_info "Examples:"
            print_info "  make link-repos BACKEND_PATH=/path/to/your/frolf-bot"
            print_info "  make link-repos DISCORD_PATH=/path/to/your/discord-frolf-bot"
            print_info "  make link-repos SHARED_PATH=/path/to/your/frolf-bot-shared"
            echo ""
            print_info "Or link all at once:"
            print_info "  make link-repos \\"
            print_info "    BACKEND_PATH=/path/to/frolf-bot \\"
            print_info "    DISCORD_PATH=/path/to/discord-frolf-bot \\"
            print_info "    SHARED_PATH=/path/to/frolf-bot-shared"
            echo ""
            print_warning "Please set up the repository links manually, then run the onboard script again."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please run this script again and choose 1, 2, or 3."
            exit 1
            ;;
    esac
else
    print_success "All repositories are already present!"
fi

wait_for_input

clear

# Step 3: Infrastructure Setup
print_header "🏗️  Step 3: Infrastructure Setup"
print_step "Time to set up the complete development infrastructure..."

print_info "This will set up:"
print_info "• Local Kubernetes cluster"
print_info "• PostgreSQL database"
print_info "• NATS messaging system"
print_info "• Monitoring stack (Grafana, Prometheus, etc.)"
print_info "• ArgoCD for GitOps"
print_info "• Multi-tenant guild management"
echo ""

print_warning "This step takes the longest (5-10 minutes) as it downloads Docker images and sets up services."
echo ""

if ask_yes_no "Start the infrastructure bootstrap process?"; then
    print_step "Starting bootstrap process..."
    print_info "You can monitor progress and see what's being installed."
    echo ""
    
    if make bootstrap; then
        print_success "Infrastructure bootstrap completed successfully!"
    else
        print_error "Bootstrap encountered issues."
        echo "Don't worry! You can:"
        echo "1. Check what failed with: make status"
        echo "2. Try individual setup steps: make setup-all"
        echo "3. Clean and retry: make clean && make bootstrap"
    fi
else
    print_warning "Skipping infrastructure setup."
    echo "You can run it later with: make bootstrap"
fi

wait_for_input

clear

# Step 4: Discord Configuration
print_header "🤖 Step 4: Discord Bot Configuration"
print_step "Let's configure your Discord bot..."

print_info "To use the Discord bot, you need:"
print_info "1. A Discord Application & Bot"
print_info "2. The bot token"
print_info "3. The bot added to your test Discord server"
echo ""

if ask_yes_no "Do you have a Discord bot token ready?"; then
    echo "Please enter your Discord bot token:"
    read -s -p "Token: " DISCORD_TOKEN
    echo ""
    
    if [ -n "$DISCORD_TOKEN" ]; then
        print_step "Configuring Discord token..."
        
        # Create namespace if it doesn't exist
        kubectl create namespace frolf-bot --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
        
        # Create or update the secret
        if kubectl patch secret discord-secrets -n frolf-bot -p "{\"data\":{\"token\":\"$(echo -n "$DISCORD_TOKEN" | base64)\"}}" >/dev/null 2>&1; then
            print_success "Discord token configured successfully!"
        else
            # Try to create the secret if patch failed
            if kubectl create secret generic discord-secrets --from-literal=token="$DISCORD_TOKEN" -n frolf-bot >/dev/null 2>&1; then
                print_success "Discord token configured successfully!"
            else
                print_error "Failed to configure Discord token. You can set it manually later."
            fi
        fi
    else
        print_warning "No token provided. You'll need to configure it manually later."
    fi
else
    print_info "To create a Discord bot:"
    print_info "1. Go to https://discord.com/developers/applications"
    print_info "2. Create a new application"
    print_info "3. Go to 'Bot' section and create a bot"
    print_info "4. Copy the bot token"
    print_info "5. Add the bot to your Discord server"
    echo ""
    print_info "You can configure the token later with:"
    echo "kubectl patch secret discord-secrets -n frolf-bot -p '{\"data\":{\"token\":\"<base64-token>\"}}"
fi

wait_for_input

clear

# Step 5: First Development Session
print_header "🚀 Step 5: Start Development"
print_step "Everything is set up! Let's start your first development session..."

print_info "The development environment uses Tilt for:"
print_info "• Automatic rebuilding when you change code"
print_info "• Live deployment to Kubernetes"
print_info "• Integrated logging and monitoring"
print_info "• Port forwarding for easy access"
echo ""

if ask_yes_no "Start the development environment now?"; then
    print_step "Starting Tilt development environment..."
    print_info "Tilt will open in your browser automatically."
    print_info "You can also access it at: http://localhost:10350"
    echo ""
    print_info "Important URLs:"
    print_info "• Backend API: http://localhost:8080"
    print_info "• Grafana: http://localhost:3000 (admin/admin)"
    print_info "• ArgoCD: http://localhost:30080"
    echo ""
    print_info "Press Ctrl+C in this terminal to stop the development environment."
    echo ""
    
    wait_for_input
    
    # Start development environment
    make dev
else
    print_info "You can start the development environment later with: make dev"
fi

clear

# Setup Complete
print_header "🎉 Setup Complete!"

print_success "Congratulations! Your Frolf Bot development environment is ready!"
echo ""

print_info "📚 What you can do now:"
print_info "• Edit code in any of the repositories"
print_info "• See changes automatically deployed via Tilt"
print_info "• Monitor applications in Grafana"
print_info "• Manage deployments with ArgoCD"
print_info "• Create test Discord guilds"
echo ""

print_info "🔧 Useful commands:"
print_info "• make dev           - Start development environment"
print_info "• make status        - Check deployment status"
print_info "• make urls          - Show all service URLs"
print_info "• make create-guild  - Create a test Discord guild"
print_info "• make help          - See all available commands"
echo ""

print_info "📖 Documentation:"
print_info "• QUICK_START.md     - Quick reference guide"
print_info "• README.md          - Complete documentation"
echo ""

print_info "🆘 Need help?"
print_info "• Check QUICK_START.md for troubleshooting"
print_info "• Run 'make verify-setup' to check your environment"
print_info "• Ask the team!"
echo ""

print_success "Happy coding! 🚀"
