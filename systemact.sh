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

# confirmation dialog

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


yad_confirm_dialog () {
    text="
    <span><big><b>${text_title}</b></big></span>

    ${text_msg}
    "
    btn_cancel="cancel"
    cancel_img="gnome-info"
    timeout=60
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
            ;;
        1|252)
            notify-send -i "$cancel_img" "$title_var" "$cancel_msg"
            ;;
    esac
}


if [ -f "$config" ]; then
    . "$config"
else
    mkdir -p "$config_dir"
    cp "$default_cfg" "$config"
fi

if [ -z "$logoutcmd" ]; then
    logoutcmd="$ctl terminate-session ${XDG_SESSION_ID}"
fi

if [ -z "$lockcmd" ]; then
    lockcmd="$ctl lock-session ${XDG_SESSION_ID}"
fi


if [ -z "$suspend_method" ]; then
    suspend_method="suspend"
fi

case "$1" in
    lock)
        $lockcmd
        ;;
    logout)
        $logoutcmd
        ;;
    shutdown|poweroff)
        $ctl poweroff
        ;;
    reboot|restart)
        $ctl reboot
        ;;
    suspend|sleep)
        $ctl "$suspend_method"
        ;;
esac
