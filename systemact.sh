#!/bin/sh

# systemctl/loginctl command
ctl=""
case "$(readlink -f /sbin/init)" in
	*systemd*) ctl='systemctl' ;;
	*) ctl='loginctl' ;;
esac

default_cfg=examples-placeholder/config.rc
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
    # check for timeout value form config
    if [ -z "$timeout" ]; then
        timeout=$def_timeout
    else
        # max cap timeout to 240 seconds
        timeout=$( max "$timeout" "$max_timeout" )
        # min cap tiemout to  15 seconds
        timeout=$( min "$timeout" "$min_timeout" )
    fi

    text="
    <span><big><b>${text_title}</b></big></span>

    ${text_msg}
    "
    btn_cancel="cancel"
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
        0)
            notify-send -i "$act_image" "$title_var" "$success_msg"
            printf '%s\n' 0
            ;;
        1|252)
            notify-send -i "$cancel_img" "$title_var" "$cancel_msg"
            printf '%s\n' 1
            ;;
    esac
}

if [ -f "$config" ]; then
    . "$config"
else
    mkdir -p "$config_dir"
    cp "$default_cfg" "$config"
fi

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

        act_image="system-log-out"
        text_title="Logout"
        text_msg="The system will log out automatically in 60 seconds."
        title_var="Logout"
        btn_act="Logout now"
        success_msg="logging out"
        cancel_msg="logout cancelled"
        yad_confirm_dialog
        ret=$?
        if [ "$ret" -eq 0 ]; then
            $logoutcmd
        fi
        ;;
    shutdown|poweroff)
        act_image="system-shutdown"
        text_title="Power Off"
        text_msg="The system will shutdown automatically in 60 seconds."
        title_var="Shutdown"
        btn_act="Shutdown now"
        success_msg="shutting down"
        cancel_msg="cancelled shutdown"
        yad_confirm_dialog
        ret=$?
        if [ "$ret" -eq 0 ]; then
            $ctl poweroff
        fi
        ;;
    reboot|restart)
        act_image="system-reboot"
        text_title="Restart"
        text_msg="The system will reboot automatically in 60 seconds."
        title_var="Reboot"
        btn_act="Rebooot now"
        success_msg="rebooting"
        cancel_msg="cancelled reboot"
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

        act_image="system-suspend"
        text_title="Sleep"
        text_msg="The system will suspend automatically in 60 seconds."
        title_var="Suspend"
        btn_act="Suspend now"
        success_msg="suspending now"
        cancel_msg="cancelled suspend"
        yad_confirm_dialog
        ret=$?
        if [ "$ret" -eq 0 ]; then
            $ctl "$suspend_method"
        fi
        ;;
esac
