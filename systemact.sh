#!/bin/sh

# defined as: "${0##*/}"
myname="${0##*/}"

version="@VERSION"

################
# message vars #
################

logout_text_title="Logout"
logout_text_msg="The system will log out automatically in"
logout_title_var="Logout"
logout_btn_act="Logout now"
logout_success_msg="logging out"
logout_cancel_msg="logout cancelled"

shutdown_text_title="Power Off"
shutdown_text_msg="The system will shutdown automatically in"
shutdown_title_var="Shutdown"
shutdown_btn_act="Shutdown now"
shutdown_success_msg="shutting down"
shutdown_cancel_msg="cancelled shutdown"

reboot_text_title="Restart"
reboot_text_msg="The system will reboot automatically in"
reboot_title_var="Reboot"
reboot_btn_act="Rebooot now"
reboot_success_msg="rebooting"
reboot_cancel_msg="cancelled reboot"

sleep_text_title="Sleep"
sleep_text_msg="The system will suspend automatically in"
sleep_title_var="Suspend"
sleep_btn_act="Suspend now"
sleep_success_msg="suspending now"
sleep_cancel_msg="cancelled suspend"

btn_cancel="Cancel"

seconds="seconds"

default_cfg=@examples/config.rc
config_dir="${HOME}/.config/systemact"
config="${config_dir}/config.rc"
logoutcmd=""

# return type: int
# usage: min value minimum_value
min () {
  if [ "$1" -lt "$2" ]; then
    result="$2"
  else
    result="$1"
  fi
  printf '%d\n' "$result"
}

# return type: int
# usage: max value maximum_value
max () {
  if [ "$1" -gt "$2" ]; then
    result="$2"
  else
    result="$1"
  fi
  printf '%d\n' "$result"
}

# confirmation dialog

# 60 seconds
def_timeout=60
# 1/4 of default: 15 seconds
min_timeout=$(( def_timeout / 4 ))
# 4x  of default: 240 seconds
max_timeout=$(( def_timeout * 4 ))
timeout=""

export TEXTDOMAINDIR="@locale"

# action image
act_image=""
# action title
text_title=""
# action message
text_msg=""
# window title in taskbar/titlebar
title_var=""
# action button text
btn_act=""
# message on success
success_msg=""
# message on cancel
cancel_msg=""


# return type: int
# return values: 0, 1
#     0: True
#     1: False
# usage: yad_confirm_dialog
yad_confirm_dialog () {
    # function's return value
    # defaulting to 1 just to be safe
    retval=1
    # check for timeout value form config
    if [ -z "$timeout" ]; then
        timeout=$def_timeout
    else
        # max cap timeout to 240 seconds
        timeout=$( max "$timeout" "$max_timeout" )
        # min cap timeout to  15 seconds
        timeout=$( min "$timeout" "$min_timeout" )
    fi

    text="
    <span><big><b>${text_title}</b></big></span>

    ${text_msg}
    "
    btn_cancel="$(gettext "$myname" "$btn_cancel")"
    cancel_img="gnome-info"
    yad \
        --image "$act_image" \
        --text "$text" \
        --buttons-layout=center \
        --skip-taskbar \
        --sticky \
        --undecorated \
        --title="$title_var" \
        --on-top \
        --button="$btn_act" \
        --button="${btn_cancel}:1" \
        --timeout-indicator="bottom" \
        --timeout="$timeout" \
        --center \
        --auto-close

    ret=$?

    case "$ret" in
        0|70)
            notify-send -i "$act_image" "$title_var" "$success_msg"
            retval=0
            ;;
        1|252)
            notify-send -i "$cancel_img" "$title_var" "$cancel_msg"
            retval=1
            ;;
    esac

    return "$retval"
}

if [ -f "$config" ]; then
    . "$config"
else
    mkdir -p "$config_dir"
    cp "$default_cfg" "$config"
fi

_help () {
        code=0
    if [ -n "$1" ]; then
        if [ -z "$2" ]; then
            av="no argument provided"
        else
            av="'$2'"
        fi
        printf '%s: %s\n' "$myname" "unknown argument, $av"
        code="$1"
    fi
    printf '%s: %s\n\n' "$myname" "logout and power menu backend utility"
    printf '%s:\n' "Usage"
    printf '\t%s\n' "${myname}:  [option] <action>"
    printf '%s: %s\n' "Version" "$version"
    printf '%s\n' "Actions available:"
    printf '\t%s\n' "lock"
    printf '\t%s\n' "logout"
    printf '\t%s\n' "shutdown/poweroff"
    printf '\t%s\n' "reboot/restart"
    printf '\t%s\n' "suspend/sleep"
    printf '%s\n' "Options:"
    printf '\t-h, --help\t\tshow this help.\n'
    printf '\t-V, --version\t\tshow program version.\n'
    exit "$code"
}

# systemctl/loginctl command
ctl=""
if command -v systemctl >/dev/null ; then
    ctl="$(command -v systemctl)"
fi
if command -v loginctl >/dev/null ; then
    ctl="$(command -v loginctl)"
fi

# return type: bool
# usage: is_call_implemented <function_name>
is_call_implemented() {
	PATH="" command -V "$1" >/dev/null 2>&1
}

# return type: exit status int
# usage: call <function_name>
# description:
#     provides mechanism for calling user override definition for called
#     function, if function_name_override exists then it is called otherwise
#     calls function_name
call() {
	cmd="$1"
	shift
	if is_call_implemented "${cmd}_override" ; then
	    ${cmd}_override "$@"
	else
        ${cmd} "$@"
    fi
}

case "$1" in
    lock)
        # check if a lock command was defined in config
        if [ -z "$lockcmd" ]; then
            # default
            lockcmd="$ctl lock-session ${XDG_SESSION_ID}"
        fi

        $lockcmd
        ;;
    logout)
        # check if a logout command was defined in config
        if [ -z "$logoutcmd" ]; then
            # default
            logoutcmd="$ctl terminate-session ${XDG_SESSION_ID}"
        fi

        logout_act_image="system-log-out"
        logout_text_title="$(gettext "$myname" "$logout_text_title")"
        logout_text_msg="$(gettext "$myname" "$logout_text_msg") $timeout $(gettext "$myname" "$seconds")."
        logout_title_var="$(gettext "$myname" "$logout_title_var")"
        logout_btn_act="$(gettext "$myname" "$logout_btn_act")"
        logout_success_msg="$(gettext "$myname" "$logout_success_msg")"
        logout_cancel_msg="$(gettext "$myname" "$logout_cancel_msg")"
        act_image="$logout_act_image"
        text_title="$logout_text_title"
        text_msg="$logout_text_msg"
        title_var="$logout_title_var"
        btn_act="$logout_btn_act"
        success_msg="$logout_success_msg"
        cancel_msg="$logout_cancel_msg"
        yad_confirm_dialog
        ret=$?
        if [ "$ret" -eq 0 ]; then
            $logoutcmd
        fi
        ;;
    shutdown|poweroff)
        shutdown_act_image="system-shutdown"
        shutdown_text_title="$(gettext "$myname" "$shutdown_text_title")"
        shutdown_text_msg="$(gettext "$myname" "$shutdown_text_msg") $timeout $(gettext "$myname" "$seconds")."
        shutdown_title_var="$(gettext "$myname" "$shutdown_title_var")"
        shutdown_btn_act="$(gettext "$myname" "$shutdown_btn_act")"
        shutdown_success_msg="$(gettext "$myname" "$shutdown_success_msg")"
        shutdown_cancel_msg="$(gettext "$myname" "$shutdown_cancel_msg")"
        act_image="$shutdown_act_image"
        text_title="$shutdown_text_title"
        text_msg="$shutdown_text_msg"
        title_var="$shutdown_title_var"
        btn_act="$shutdown_btn_act"
        success_msg="$shutdown_success_msg"
        cancel_msg="$shutdown_cancel_msg"
        yad_confirm_dialog
        ret=$?
        if [ "$ret" -eq 0 ]; then
            $ctl poweroff
        fi
        ;;
    reboot|restart)
        reboot_act_image="system-reboot"
        reboot_text_title="$(gettext "$myname" "$reboot_text_title")"
        reboot_text_msg="$(gettext "$myname" "$reboot_text_msg") $timeout $(gettext "$myname" "$seconds")."
        reboot_title_var="$(gettext "$myname" "$reboot_title_var")"
        reboot_btn_act="$(gettext "$myname" "$reboot_btn_act")"
        reboot_success_msg="$(gettext "$myname" "$reboot_success_msg")"
        reboot_cancel_msg="$(gettext "$myname" "$reboot_cancel_msg")"
        act_image="$reboot_act_image"
        text_title="$reboot_text_title"
        text_msg="$reboot_text_msg"
        title_var="$reboot_title_var"
        btn_act="$reboot_btn_act"
        success_msg="$reboot_success_msg"
        cancel_msg="$reboot_cancel_msg"
        yad_confirm_dialog
        ret=$?
        if [ "$ret" -eq 0 ]; then
            $ctl reboot
        fi
        ;;
    suspend|sleep)
        # check if a suspend method was defined in config
        if [ -z "$suspend_method" ]; then
            # default
            suspend_method="suspend"
        fi

        sleep_act_image="system-suspend"
        sleep_text_title="$(gettext "$myname" "$sleep_text_title")"
        sleep_text_msg="$(gettext "$myname" "$sleep_text_msg") $timeout $(gettext "$myname" "$seconds")."
        sleep_title_var="$(gettext "$myname" "$sleep_title_var")"
        sleep_btn_act="$(gettext "$myname" "$sleep_btn_act")"
        sleep_success_msg="$(gettext "$myname" "$sleep_success_msg")"
        sleep_cancel_msg="$(gettext "$myname" "$sleep_cancel_msg")"
        act_image="$sleep_act_image"
        text_title="$sleep_text_title"
        text_msg="$sleep_text_msg"
        title_var="$sleep_title_var"
        btn_act="$sleep_btn_act"
        success_msg="$sleep_success_msg"
        cancel_msg="$sleep_cancel_msg"
        yad_confirm_dialog
        ret=$?
        if [ "$ret" -eq 0 ]; then
            $ctl "$suspend_method"
        fi
        ;;
    -h|--help|help)
        _help
        ;;
    -V|--version|version)
        printf '%s\n' "$version"
        ;;
    *)
        _help 1 "${1}"
        ;;
esac
