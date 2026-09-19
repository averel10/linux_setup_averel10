#!/bin/bash

set -u

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

# Components are auto-discovered: every "<dir>/component.conf" registers the
# component "<dir>". The manifest sets COMPONENT_DESCRIPTION and COMPONENT_ORDER.
COMPONENT_NAMES=()
declare -A COMPONENT_DESC=()
declare -A COMPONENT_PATH=()

load_components() {
    local conf dir name order desc line
    local entries=()

    for conf in "$SCRIPT_DIR"/*/component.conf; do
        [ -e "$conf" ] || continue
        dir="$(dirname "$conf")"
        name="$(basename "$dir")"
        desc=""
        order=100
        # shellcheck disable=SC1090,SC1091
        . "$conf" || { warn "Skipping unreadable component: $conf"; continue; }
        desc="$COMPONENT_DESCRIPTION"
        order="$COMPONENT_ORDER"
        entries+=("$(printf '%05d %s' "$order" "$name")")
        COMPONENT_DESC[$name]="$desc"
        COMPONENT_PATH[$name]="$dir"
    done

    COMPONENT_NAMES=()
    if [ ${#entries[@]} -gt 0 ]; then
        while IFS= read -r line; do
            COMPONENT_NAMES+=("${line#* }")
        done < <(printf '%s\n' "${entries[@]}" | sort)
    fi
}

has_component() {
    local name
    for name in ${COMPONENT_NAMES[@]+"${COMPONENT_NAMES[@]}"}; do
        [ "$name" = "$1" ] && return 0
    done
    return 1
}

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
  doctor                Report the state of each component
  help                  Show this help message

${CYAN}COMPONENTS:${NC}
$(for c in ${COMPONENT_NAMES[@]+"${COMPONENT_NAMES[@]}"}; do echo "  $c"; done)
  all                   All components

${CYAN}EXAMPLES:${NC}
  $(basename "$0") install              # Interactive menu
  $(basename "$0") install ozsh         # Install Oh My Zsh
  $(basename "$0") install all          # Install all components
  $(basename "$0") remove ozsh          # Remove Oh My Zsh
  $(basename "$0") -n install all       # Preview without changing anything
  $(basename "$0") doctor               # Report component status
  $(basename "$0") list                 # List components

${CYAN}OPTIONS:${NC}
  -h, --help            Show this help message
  -q, --quiet           Suppress status output
  -n, --dry-run         Preview actions without changing anything
EOF
}

list_components() {
    echo -e "${CYAN}Available Components:${NC}\n"
    local i name
    for (( i=0; i<${#COMPONENT_NAMES[@]}; i++ )); do
        name="${COMPONENT_NAMES[$i]}"
        echo -e "  ${BLUE}$((i+1))${NC} - ${name}: ${COMPONENT_DESC[$name]}"
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
                CHOSEN=("${COMPONENT_NAMES[@]}")
                return 0
                ;;
            q|quit)
                return 2
                ;;
            ''|*[!0-9]*)
                error "Invalid selection: '$token'"
                return 1
                ;;
            *)
                if (( token >= 1 && token <= ${#COMPONENT_NAMES[@]} )); then
                    CHOSEN+=("${COMPONENT_NAMES[$((token-1))]}")
                else
                    error "Invalid selection: '$token'"
                    return 1
                fi
                ;;
        esac
    done

    if [ ${#CHOSEN[@]} -eq 0 ]; then
        error "No components selected"
        return 1
    fi
}

run_component() {
    local action=$1 name=$2 script
    script="${COMPONENT_PATH[$name]}/scripts/${action}.sh"
    if [ ! -f "$script" ]; then
        error "✗ No $action script for component: $name"
        return 1
    fi
    SETUP_QUIET="$SETUP_QUIET" SETUP_DRY_RUN="$SETUP_DRY_RUN" bash "$script"
}

install_component() {
    local name=$1
    if ! has_component "$name"; then
        error "✗ Unknown component: $name"
        return 1
    fi
    say "${YELLOW}Installing $name...${NC}\n"
    run_component install "$name"
}

remove_component() {
    local name=$1
    if ! has_component "$name"; then
        error "✗ Unknown component: $name"
        return 1
    fi
    say "${YELLOW}Removing $name...${NC}\n"
    run_component remove "$name"
}

doctor_component() {
    local name=$1 script="${COMPONENT_PATH[$1]}/scripts/doctor.sh"
    say "${BLUE}== ${name} ==${NC}"
    if [ -f "$script" ]; then
        SETUP_QUIET="$SETUP_QUIET" bash "$script"
    else
        say "  no doctor available"
    fi
}

doctor_all() {
    local rc=0 name
    say "${CYAN}Component doctor${NC}\n"
    for name in ${COMPONENT_NAMES[@]+"${COMPONENT_NAMES[@]}"}; do
        doctor_component "$name" || rc=1
    done
    return $rc
}

install_all() {
    say "${YELLOW}Installing all components...${NC}\n"
    local name rc=0
    for name in ${COMPONENT_NAMES[@]+"${COMPONENT_NAMES[@]}"}; do
        say "${BLUE}→ Installing ${name}${NC}"
        install_component "$name" || rc=1
    done
    return $rc
}

remove_all() {
    say "${YELLOW}Removing all components...${NC}\n"
    if ! ask_yes_no "Are you sure? This will remove all components (y/N):" n; then
        say "${YELLOW}Cancelled.${NC}"
        return 0
    fi

    local name rc=0
    for name in ${COMPONENT_NAMES[@]+"${COMPONENT_NAMES[@]}"}; do
        say "${BLUE}→ Removing ${name}${NC}"
        remove_component "$name" || rc=1
    done
    return $rc
}

show_success() {
    local action=$1
    if [ "$SETUP_DRY_RUN" = "1" ]; then
        say "\n${YELLOW}(dry-run) ${action^} previewed; nothing was changed.${NC}\n"
        return 0
    fi
    say "\n${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    say "${GREEN}║      ${action^} Complete!${NC}"
    say "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}\n"
}

show_failure() {
    local action=$1
    error "✗ ${action^} failed. See the output above for details."
}

# Run a chosen batch of components for one action, returning non-zero if any fail.
run_selected() {
    local action=$1 rc=0 name
    for name in ${CHOSEN[@]+"${CHOSEN[@]}"}; do
        case $action in
            install) install_component "$name" || rc=1 ;;
            remove)  remove_component "$name" || rc=1 ;;
        esac
    done
    return $rc
}

# Main logic
main() {
    local command=${1:-}
    local component=${2:-}
    local rc=0 action_word

    case $command in
        install|remove)
            if [ "$command" = "install" ]; then
                action_word="installation"
            else
                action_word="removal"
            fi

            if [ -z "$component" ]; then
                choose_components "$command"
                case $? in
                    0) run_selected "$command" || rc=1 ;;
                    2) say "${YELLOW}Cancelled.${NC}"; exit 0 ;;
                    *) exit 1 ;;
                esac
            elif [ "$component" = "all" ]; then
                if [ "$command" = "install" ]; then
                    install_all || rc=1
                else
                    remove_all || rc=1
                fi
            elif [ "$command" = "install" ]; then
                install_component "$component" || rc=1
            else
                remove_component "$component" || rc=1
            fi

            if [ $rc -eq 0 ]; then
                show_success "$action_word"
            else
                show_failure "$action_word"
                exit 1
            fi
            ;;
        list)
            list_components
            ;;
        doctor)
            doctor_all
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
            say "  ${BLUE}5${NC} - Doctor"
            say "  ${BLUE}q${NC} - Quit\n"

            local reply
            read -r -p "Choose an action (1-5/q): " reply || true
            echo -e "\n"

            case $reply in
                1) main install ;;
                2) main remove ;;
                3) main list ;;
                4) main help ;;
                5) main doctor ;;
                q) say "${YELLOW}Goodbye!${NC}"; exit 0 ;;
                *) error "✗ Invalid option"; exit 1 ;;
            esac
            ;;
        *)
            error "✗ Unknown command: $command"
            error "Use '$(basename "$0") help' for usage information"
            exit 1
            ;;
    esac
}

load_components

# Parse global options, then dispatch.
ARGS=()
while [ $# -gt 0 ]; do
    case $1 in
        -q|--quiet)
            SETUP_QUIET=1
            shift
            ;;
        -n|--dry-run)
            SETUP_DRY_RUN=1
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
