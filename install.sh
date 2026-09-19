#!/bin/bash

set -u

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Components must be listed in COMPONENT_ORDER (menu numbering follows it) and
# described in COMPONENTS. Both are used by list_components/install_all.
COMPONENT_ORDER=(ozsh)
declare -A COMPONENTS=(
    [ozsh]="Oh My Zsh - Spaceship prompt + plugins"
)

QUIET=0

# Print a status/decorative message unless --quiet was passed.
say() {
    [ "$QUIET" -eq 1 ] || echo -e "$@"
}

# Read a whole line so the trailing newline is not left for the next prompt.
# Usage: ask_yes_no "Question?" n   (defaults to no)
ask_yes_no() {
    local prompt=$1 default=${2:-n} reply
    read -r -p "$prompt " reply || true
    case $default in
        y|Y) [[ ! $reply =~ ^[Nn]$ ]] ;;
        *)   [[ $reply =~ ^[Yy]$ ]] ;;
    esac
}

# Functions
show_help() {
    cat << EOF
${BLUE}╔══════════════════════════════════════════════════════════╗${NC}
${BLUE}║        Linux Setup - Component Management CLI             ║${NC}
${BLUE}╚══════════════════════════════════════════════════════════╝${NC}

${CYAN}USAGE:${NC}
  $(basename "$0") [COMMAND] [COMPONENT] [OPTIONS]

${CYAN}COMMANDS:${NC}
  install [COMPONENT]   Install component(s)
  remove [COMPONENT]    Remove component(s)
  list                  List available components
  help                  Show this help message

${CYAN}COMPONENTS:${NC}
$(for c in "${COMPONENT_ORDER[@]}"; do echo "  $c"; done)
  all                   All components

${CYAN}EXAMPLES:${NC}
  $(basename "$0") install              # Interactive menu
  $(basename "$0") install ozsh         # Install Oh My Zsh
  $(basename "$0") install all          # Install all components
  $(basename "$0") remove ozsh          # Remove Oh My Zsh
  $(basename "$0") list                 # List components

${CYAN}OPTIONS:${NC}
  -h, --help            Show this help message
  -q, --quiet           Suppress status output
EOF
}

list_components() {
    echo -e "${CYAN}Available Components:${NC}\n"
    local i
    for (( i=0; i<${#COMPONENT_ORDER[@]}; i++ )); do
        echo -e "  ${BLUE}$((i+1))${NC} - ${COMPONENT_ORDER[$i]}: ${COMPONENTS[${COMPONENT_ORDER[$i]}]}"
    done
    echo
}

# Populate the global CHOSEN array from the user's interactive selection.
# Returns 0 on success, 2 to quit, 1 on invalid input.
choose_components() {
    local mode=$1
    list_components

    say "${YELLOW}${mode^} Options:${NC}\n"
    say "  ${BLUE}a${NC} - $mode all components"
    say "  ${BLUE}q${NC} - Quit without $mode\n"

    local input
    read -r -p "Select component(s) to $mode (numbers separated by spaces, a, q): " input || true
    input="${input//,/ }"

    CHOSEN=()
    local token
    for token in $input; do
        case $token in
            a|all)
                CHOSEN=("${COMPONENT_ORDER[@]}")
                return 0
                ;;
            q|quit)
                return 2
                ;;
            ''|*[!0-9]*)
                say "${RED}✗ Invalid selection: '$token'${NC}"
                return 1
                ;;
            *)
                if (( token >= 1 && token <= ${#COMPONENT_ORDER[@]} )); then
                    CHOSEN+=("${COMPONENT_ORDER[$((token-1))]}")
                else
                    say "${RED}✗ Invalid selection: '$token'${NC}"
                    return 1
                fi
                ;;
        esac
    done

    if [ ${#CHOSEN[@]} -eq 0 ]; then
        say "${RED}✗ No components selected${NC}"
        return 1
    fi
}

install_component() {
    local component=$1

    case $component in
        ozsh)
            say "${YELLOW}Installing Oh My Zsh setup...${NC}\n"
            SETUP_QUIET=$QUIET bash "$SCRIPT_DIR/ozsh/scripts/install.sh"
            ;;
        *)
            say "${RED}✗ Unknown component: $component${NC}"
            return 1
            ;;
    esac
}

remove_component() {
    local component=$1

    case $component in
        ozsh)
            say "${YELLOW}Removing Oh My Zsh setup...${NC}\n"
            SETUP_QUIET=$QUIET bash "$SCRIPT_DIR/ozsh/scripts/remove.sh"
            ;;
        *)
            say "${RED}✗ Unknown component: $component${NC}"
            return 1
            ;;
    esac
}

install_all() {
    say "${YELLOW}Installing all components...${NC}\n"
    local component rc=0
    for component in "${COMPONENT_ORDER[@]}"; do
        say "${BLUE}→ Installing ${component}${NC}"
        install_component "$component" || rc=1
    done
    return $rc
}

remove_all() {
    say "${YELLOW}Removing all components...${NC}\n"
    if ! ask_yes_no "Are you sure? This will remove all components (y/N):" n; then
        say "${YELLOW}Cancelled.${NC}"
        return 0
    fi

    local component rc=0
    for component in "${COMPONENT_ORDER[@]}"; do
        say "${BLUE}→ Removing ${component}${NC}"
        remove_component "$component" || rc=1
    done
    return $rc
}

show_success() {
    local action=$1
    say "\n${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    say "${GREEN}║      ${action^} Complete!${NC}"
    say "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}\n"
}

show_failure() {
    local action=$1
    say "\n${RED}✗ ${action^} failed. See the output above for details.${NC}\n"
}

# Main logic
main() {
    local command=${1:-}
    local component=${2:-}
    local rc=0

    case $command in
        install)
            if [ -z "$component" ]; then
                choose_components "install"
                case $? in
                    0)
                        local c
                        for c in "${CHOSEN[@]}"; do
                            install_component "$c" || rc=1
                        done
                        ;;
                    2)
                        say "${YELLOW}Cancelled.${NC}"
                        exit 0
                        ;;
                    *)
                        exit 1
                        ;;
                esac
            elif [ "$component" = "all" ]; then
                install_all || rc=1
            else
                install_component "$component" || rc=1
            fi

            if [ $rc -eq 0 ]; then
                show_success "installation"
            else
                show_failure "installation"
                exit 1
            fi
            ;;
        remove)
            if [ -z "$component" ]; then
                choose_components "remove"
                case $? in
                    0)
                        local c
                        for c in "${CHOSEN[@]}"; do
                            remove_component "$c" || rc=1
                        done
                        ;;
                    2)
                        say "${YELLOW}Cancelled.${NC}"
                        exit 0
                        ;;
                    *)
                        exit 1
                        ;;
                esac
            elif [ "$component" = "all" ]; then
                remove_all || rc=1
            else
                remove_component "$component" || rc=1
            fi

            if [ $rc -eq 0 ]; then
                show_success "removal"
            else
                show_failure "removal"
                exit 1
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

            say "${YELLOW}Select an action:${NC}\n"
            say "  ${BLUE}1${NC} - Install components"
            say "  ${BLUE}2${NC} - Remove components"
            say "  ${BLUE}3${NC} - List components"
            say "  ${BLUE}4${NC} - Show help"
            say "  ${BLUE}q${NC} - Quit\n"

            local reply
            read -r -p "Choose an action (1-4/q): " reply || true
            echo -e "\n"

            case $reply in
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
                    say "${YELLOW}Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    say "${RED}✗ Invalid option${NC}"
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

# Parse global options, then dispatch.
ARGS=()
while [ $# -gt 0 ]; do
    case $1 in
        -q|--quiet)
            QUIET=1
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

main ${ARGS[@]+"${ARGS[@]}"}
