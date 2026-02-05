#!/bin/sh

# defined as: "${0##*/}"
myname="${0##*/}"

version="@VERSION"

DBGOUT=""
DRYRUN=""
NO_DIALOG=""

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

hibernate_text_title="Hibernate"
hibernate_text_msg="The system will hibernate automatically in"
hibernate_title_var="Hibernate"
hibernate_btn_act="Hibernate now"
hibernate_success_msg="Hibernate now"
hibernate_cancel_msg="cancelled hibernate"

btn_cancel="Cancel"

seconds="seconds"

default_cfg=@examples/config.rc
config_dir="${HOME}/.config/systemact"
config="${config_dir}/config.rc"
logoutcmd=""
lockcmd=""

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

export TEXTDOMAINDIR="@localeprefix"

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

# usage: dbgprint "message"
# description: print debug messages
dbgprint (){
    if [ -n "$DBGOUT" ]; then
        printf '%s: %s\n' "$myname" "$*"
    fi
}

# return type: int
# return values: 0, 1
#     0: True
#     1: False
# usage: yad_confirm_dialog img title msg sec tvar btn success cancel
#         img: act_image
#       title: text_title
#         msg: text_msg
#         sec: seconds
#        tvar: title_var
#         btn: btn_act
#     success: success_msg
#      cancel: cancel_msg
yad_confirm_dialog () {
    act_image="$1"
    text_title="$2"
    text_msg="$3"
    seconds="$4"
    title_var="$5"
    btn_act="$6"
    success_msg="$7"
    cancel_msg="$8"
    case "$LANGUAGE" in
        C*|en*)
            : # do nothing, no need to translate text
            dbgprint "language '$LANGUAGE', no attempt to translate"
            ;;
        *)
            dbgprint "language '$LANGUAGE', trying to find translations"
            # try to translate text
            text_title="$(gettext  "$myname" "$text_title")"
            text_msg="$(gettext    "$myname" "$text_msg")"
            seconds="$(gettext     "$myname" "$seconds")"
            title_var="$(gettext   "$myname" "$title_var")"
            btn_act="$(gettext     "$myname" "$btn_act")"
            success_msg="$(gettext "$myname" "$success_msg")"
            cancel_msg="$(gettext  "$myname" "$cancel_msg")"
            btn_cancel="$(gettext  "$myname" "$btn_cancel")"
            ;;
    esac
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

    text_msg="$text_msg $timeout $seconds."
    text="
    <span><big><b>${text_title}</b></big></span>

    ${text_msg}
    "
    cancel_img="gnome-info"
    if [ -z "$NO_DIALOG" ]; then
        dbgprint "runnign yad"
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
    else
        ret=0
    fi

    dbgprint "yad returned with '$ret'"

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

    dbgprint "yad_confirm_dialog retval '$retval'"
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
    printf '\t%s\n' "sleep"
    printf '\t%s\n' "suspend"
    printf '\t%s\n' "hibernate"
    printf '%s\n' "Options:"
    printf '\t-N, --no-dialog\t\tshow no confirmation dialog, always perform action.\n'
    printf '\t-h, --help\t\tshow this help.\n'
    printf '\t-V, --version\t\tshow program version.\n'
    printf '\t-d, --debug\t\tshow debug output.\n'
    printf '\t-n, --dryrun\t\trun the program but perform no action.\n'
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
if command -v ck-launch-session >/dev/null ; then
    ctl="consolekit"
fi

systemloginctl_handler () {
    Action="$1"
    shift
    opt="$*"
    dbgprint "handling $ctl $Action $opt"
    if [ -z "$DRYRUN" ]; then
        $ctl "$Action" "$@"
    else
        echo "$(command -v "$ctl") $Action $*"
    fi
}

consolekit_handler () {
    Action="$1"
    opt="$*"
    case "$Action" in
        lock-session)
            dbgprint "$ctl unsupported action: $Action"
            Action=""
            opt=""
            ;;
        terminate-session)
            dbgprint "$ctl unsupported action: $Action"
            Action=""
            opt=""
            ;;
        poweroff)
            Action="Stop"
            ;;
        reboot)
            Action="Restart"
            ;;
        suspend)
            Action="Suspend"
            opt="boolean:true"
            ;;
        hibernate)
            Action="Hibernate"
            opt="boolean:true"
            ;;
        hybrid-sleep)
            Action="HybridSleep"
            opt="boolean:true"
            ;;
        suspend-then-hibernate)
            dbgprint "$ctl unsupported action: $Action"
            Action=""
            opt=""
            ;;
    esac
    if [ -z "$Action" ]; then
        exit 1
    else
        dbgprint "handling $ctl $Action $opt"
        if [ -z "$DRYRUN" ]; then
            dbus-send \
                --system \
                --print-reply \
                --dest="org.freedesktop.ConsoleKit" /org/freedesktop/ConsoleKit/Manager \
                "org.freedesktop.ConsoleKit.Manager.$Action" "$opt"
        else
            echo "dbus-send \\"
            echo "    --system \\"
            echo "    --print-reply \\"
            echo "    --dest=\"org.freedesktop.ConsoleKit\" /org/freedesktop/ConsoleKit/Manager \\"
            echo "    \"org.freedesktop.ConsoleKit.Manager.$Action\" \"$opt\""
        fi
    fi
}

# usage: do_ctl action options
# action:
#         lock-session
#         terminate-session
#         poweroff
#         reboot
#         suspend
#         hibernate
#         hybrid-sleep
#         suspend-then-hibernate
do_ctl () {
    action="$1"
    shift
    dbgprint "handling $action with $ctl"
    case "$ctl" in
        *systemctl|*loginctl)
            systemloginctl_handler "$action" "$@"
            ;;
        consolekit)
            consolekit_handler "$action" "$@"
            ;;
    esac
}

do_lock () {
    # check if a lock command was defined in config
    if [ -z "$lockcmd" ]; then
        # default
        do_ctl lock-session "${XDG_SESSION_ID}"
    else
        dbgprint "locking with '$lockcmd'"
        if [ -z "$DRYRUN" ]; then
            $lockcmd
        else
            echo "$lockcmd"
        fi
    fi

}

do_logout () {
    # check if a logout command was defined in config
    if [ -z "$logoutcmd" ]; then
        # default
        do_ctl terminate-session "${XDG_SESSION_ID}"
    else
        dbgprint "logging out with '$logoutcmd'"
        if [ -z "$DRYRUN" ]; then
            $logoutcmd
        else
            echo "$logoutcmd"
        fi
    fi

}

do_poweroff () {
    do_ctl poweroff
}

do_reboot () {
    do_ctl reboot
}

do_suspend () {
    do_ctl suspend
}

do_hibernate () {
    do_ctl hibernate
}

do_hybrid_sleep () {
    do_ctl hybrid-sleep
}

do_suspend_then_hibernate () {
    do_ctl suspend-then-hibernate
}

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
        dbgprint "calling ${cmd}_override"
	    ${cmd}_override "$@"
	else
        dbgprint "calling $cmd"
        ${cmd} "$@"
    fi
}

# return type: exit status int
# usage: do_sleep
# description:
#     wrapper function that checks the configurable $suspend_method variable and then calls
#     the corresponding function
do_sleep () {
    # check if a suspend method was defined in config
    if [ -z "$suspend_method" ]; then
        # default
        suspend_method="suspend"
    fi
    case "$suspend_method" in
        suspend)
            call do_suspend
            ;;
        hibernate)
            call do_hibernate
            ;;
        hybrid-sleep)
            call do_hybrid_sleep
            ;;
        suspend-then-hibernate)
            call do_suspend_then_hibernate
            ;;
        *)
            call do_suspend
            ;;
    esac
}

while [ $# -gt 0 ]; do case "$1" in
    debug|-debug|--debug|-d)
        DBGOUT=1
        dbgprint "showing debug output"
        ;;
    dryrun|-dryrun|--dryrun|-n)
        DRYRUN=1
        dbgprint "dryrun mode"
        ;;
    nodialog|-nodialog|--no-dialog|-N)
        NO_DIALOG=1
        dbgprint "no dialog mode"
        ;;
    lock)
        dbgprint "calling action '$1'"
        call do_lock
        ;;
    logout)
        dbgprint "calling action '$1'"
        yad_confirm_dialog \
            "system-log-out" \
            "$logout_text_title" \
            "$logout_text_msg" \
            "$seconds" \
            "$logout_title_var" \
            "$logout_btn_act" \
            "$logout_success_msg" \
            "$logout_cancel_msg"
        ret=$?
        if [ "$ret" -eq 0 ]; then
            call do_logout
        fi
        ;;
    shutdown|poweroff)
        dbgprint "calling action '$1'"
        yad_confirm_dialog \
            "system-shutdown" \
            "$shutdown_text_title" \
            "$shutdown_text_msg" \
            "$seconds" \
            "$shutdown_title_var" \
            "$shutdown_btn_act" \
            "$shutdown_success_msg" \
            "$shutdown_cancel_msg"
        ret=$?
        if [ "$ret" -eq 0 ]; then
            call do_poweroff
        fi
        ;;
    reboot|restart)
        dbgprint "calling action '$1'"
        yad_confirm_dialog \
            "system-reboot" \
            "$reboot_text_title" \
            "$reboot_text_msg" \
            "$seconds" \
            "$reboot_title_var" \
            "$reboot_btn_act" \
            "$reboot_success_msg" \
            "$reboot_cancel_msg"
        ret=$?
        if [ "$ret" -eq 0 ]; then
            call do_reboot
        fi
        ;;
    suspend|sleep)
        dbgprint "calling action '$1'"
        yad_confirm_dialog \
            "system-suspend" \
            "$sleep_text_title" \
            "$sleep_text_msg" \
            "$seconds" \
            "$sleep_title_var" \
            "$sleep_btn_act" \
            "$sleep_success_msg" \
            "$sleep_cancel_msg"
        ret=$?
        if [ "$ret" -eq 0 ]; then
            case "$1" in
                sleep)
                    call do_sleep
                    ;;
                suspend)
                    call do_suspend
                    ;;
            esac
        fi
        ;;
    hibernate)
        dbgprint "calling action '$1'"
        yad_confirm_dialog \
            "system-hibernate" \
            "$hibernate_text_title" \
            "$hibernate_text_msg" \
            "$seconds" \
            "$hibernate_title_var" \
            "$hibernate_btn_act" \
            "$hibernate_success_msg" \
            "$hibernate_cancel_msg"
        ret=$?
        if [ "$ret" -eq 0 ]; then
            call do_hibernate
        fi
        ;;
    -h|--help|help)
        _help
        ;;
    -V|--version|version)
        printf '%s\n' "$version"
        ;;
    --)
        : # do nothing
        ;;
    -*)
        while getopts "dnNhV-" o "$1"; do case "${o}" in
            d)
                DBGOUT=1
                dbgprint "showing debug output"
                ;;
            n)
                DRYRUN=1
                dbgprint "dryrun mode"
                ;;
            N)
                NO_DIALOG=1
                dbgprint "no dialog mode"
                ;;
            h)
                _help
                ;;
            V)
                printf '%s\n' "$version"
                ;;
            *)
                _help 1 "${1}"
                ;;
        esac done
        ;;
    *)
        _help 1 "${1}"
        ;;
esac
shift
done
