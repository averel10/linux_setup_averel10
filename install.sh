#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Available components
declare -A COMPONENTS=(
    [ozsh]="Oh My Zsh - Spaceship prompt + plugins"
)

# Functions
show_help() {
    cat << EOF
${BLUE}╔══════════════════════════════════════════════════════════╗${NC}
${BLUE}║        Linux Setup - Component Management CLI             ║${NC}
${BLUE}╚══════════════════════════════════════════════════════════╝${NC}

${CYAN}USAGE:${NC}
  $(basename "$0") [COMMAND] [OPTIONS]

${CYAN}COMMANDS:${NC}
  install [COMPONENT]   Install component(s)
  remove [COMPONENT]    Remove component(s)
  list                  List available components
  help                  Show this help message

${CYAN}COMPONENTS:${NC}
  ozsh                  Oh My Zsh with Spaceship prompt
  all                   All components

${CYAN}EXAMPLES:${NC}
  $(basename "$0") install              # Interactive menu
  $(basename "$0") install ozsh         # Install Oh My Zsh
  $(basename "$0") install all          # Install all components
  $(basename "$0") remove ozsh          # Remove Oh My Zsh
  $(basename "$0") list                 # List components

${CYAN}OPTIONS:${NC}
  -h, --help            Show this help message
  -q, --quiet           Suppress output messages

EOF
}

list_components() {
    echo -e "${CYAN}Available Components:${NC}\n"
    local i=1
    for component in "${!COMPONENTS[@]}"; do
        echo -e "  ${BLUE}$i${NC} - ${component}: ${COMPONENTS[$component]}"
        ((i++))
    done
    echo
}

show_menu() {
    local mode=$1
    list_components
    
    if [ "$mode" = "install" ]; then
        echo -e "${YELLOW}Installation Options:${NC}\n"
        echo -e "  ${BLUE}a${NC} - $mode all components"
        echo -e "  ${BLUE}q${NC} - Quit without $mode\n"
        read -p "Select component(s) to $mode (1/a/q): " -n 1 -r
    else
        echo -e "${YELLOW}Removal Options:${NC}\n"
        echo -e "  ${BLUE}a${NC} - $mode all components"
        echo -e "  ${BLUE}q${NC} - Quit without $mode\n"
        read -p "Select component(s) to $mode (1/a/q): " -n 1 -r
    fi
    
    echo -e "\n"
}

install_component() {
    local component=$1
    
    case $component in
        ozsh)
            echo -e "${YELLOW}Installing Oh My Zsh setup...${NC}\n"
            bash "$SCRIPT_DIR/ozsh/scripts/install.sh"
            ;;
        *)
            echo -e "${RED}✗ Unknown component: $component${NC}"
            return 1
            ;;
    esac
}

remove_component() {
    local component=$1
    
    case $component in
        ozsh)
            echo -e "${YELLOW}Removing Oh My Zsh setup...${NC}\n"
            bash "$SCRIPT_DIR/ozsh/scripts/remove.sh"
            ;;
        *)
            echo -e "${RED}✗ Unknown component: $component${NC}"
            return 1
            ;;
    esac
}

install_all() {
    echo -e "${YELLOW}Installing all components...${NC}\n"
    for component in "${!COMPONENTS[@]}"; do
        echo -e "${BLUE}→ Installing ${component}${NC}"
        install_component "$component"
    done
}

remove_all() {
    echo -e "${YELLOW}Removing all components...${NC}\n"
    read -p "Are you sure? This will remove all components (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        return 0
    fi
    
    for component in "${!COMPONENTS[@]}"; do
        echo -e "${BLUE}→ Removing ${component}${NC}"
        remove_component "$component"
    done
}

show_success() {
    local action=$1
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ${action^} Complete!${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}\n"
}

# Main logic
main() {
    local command=${1:-}
    local component=${2:-}
    
    case $command in
        install)
            if [ -z "$component" ]; then
                show_menu "install"
                case $REPLY in
                    1)
                        install_component "ozsh"
                        show_success "installation"
                        ;;
                    a)
                        install_all
                        show_success "installation"
                        ;;
                    q)
                        echo -e "${YELLOW}Cancelled.${NC}"
                        exit 0
                        ;;
                    *)
                        echo -e "${RED}✗ Invalid option${NC}"
                        exit 1
                        ;;
                esac
            else
                if [ "$component" = "all" ]; then
                    install_all
                else
                    install_component "$component"
                fi
                show_success "installation"
            fi
            ;;
        remove)
            if [ -z "$component" ]; then
                show_menu "remove"
                case $REPLY in
                    1)
                        remove_component "ozsh"
                        show_success "removal"
                        ;;
                    a)
                        remove_all
                        show_success "removal"
                        ;;
                    q)
                        echo -e "${YELLOW}Cancelled.${NC}"
                        exit 0
                        ;;
                    *)
                        echo -e "${RED}✗ Invalid option${NC}"
                        exit 1
                        ;;
                esac
            else
                if [ "$component" = "all" ]; then
                    remove_all
                else
                    remove_component "$component"
                fi
                show_success "removal"
            fi
            ;;
        list)
            list_components
            ;;
        help|-h|--help)
            show_help
            ;;
        "")
            # No arguments - show interactive menu
            echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${BLUE}║     Linux Setup - Component Management${NC}"
            echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}\n"
            
            echo -e "${YELLOW}Select an action:${NC}\n"
            echo -e "  ${BLUE}1${NC} - Install components"
            echo -e "  ${BLUE}2${NC} - Remove components"
            echo -e "  ${BLUE}3${NC} - List components"
            echo -e "  ${BLUE}4${NC} - Show help"
            echo -e "  ${BLUE}q${NC} - Quit\n"
            
            read -p "Choose an action (1-4/q): " -n 1 -r
            echo -e "\n"
            
            case $REPLY in
                1)
                    main install
                    ;;
                2)
                    main remove
                    ;;
                3)
                    main list
                    ;;
                4)
                    main help
                    ;;
                q)
                    echo -e "${YELLOW}Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}✗ Invalid option${NC}"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo -e "${RED}✗ Unknown command: $command${NC}"
            echo -e "${YELLOW}Use '$(basename "$0") help' for usage information${NC}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
