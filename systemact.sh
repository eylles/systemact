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
