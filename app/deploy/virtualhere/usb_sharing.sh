#!/bin/sh
#
# Program to manage USB sharing functionality

PROGRAM=/home/steam/bin/vhusbdarmsl
CONFIG=/var/lib/vhusbdarm/vhusbdarm.ini
LOGFILE=/tmp/vhusbdarm.log

# Return whether the program is running
IsRunning()
{
    if [ "$(pidof $PROGRAM)" = "" ]; then
        return 1
    else
        return 0
    fi
}

# Add a key to the configuration file if it doesn't already exist
AddConfig()
{
    if grep "$1=" $CONFIG >/dev/null; then
        # We have this key
        return
    fi
    echo "$1=$2" >>$CONFIG
}

# Add an entry to the ignored list, if it doesn't already exist
AddIgnored()
{
    IGNORED=/tmp/ignored_list.txt
    grep "IgnoredDevices=" $CONFIG | awk -F= '{print $2}' | tr ',' '\n' >$IGNORED
    while [ $# -ne 0 ]; do
        echo $1 >>$IGNORED
        shift
    done
    entries=$(sort $IGNORED | uniq | tr '\n' ',')
    rm $IGNORED

    if grep "IgnoredDevices=" $CONFIG >/dev/null; then
        sed -i "s|IgnoredDevices=.*|IgnoredDevices=$entries|" $CONFIG
    else
        echo "IgnoredDevices=$entries" >>$CONFIG
    fi
}

# Update configuration file
UpdateConfig()
{
    # Make sure the config file exists
    if [ ! -f $CONFIG ]; then
        mkdir -p "$(dirname $CONFIG)"
        touch $CONFIG
    fi

    # Set the servername
    AddConfig "ServerName" "Steam Link"

    # Set the license (comes from Steam)
    AddConfig "License" "${LICENSE}"
    # Make sure devices are reattached when streaming stops
    AddConfig "AutoAttachToKernel" "1"

    # Add Logitech wheel config
    AddConfig "onEnumeration.046d.c294" "ltwheelnative.sh"
    AddConfig "onReset.046d.c298" ""
    AddConfig "onReset.046d.c299" ""
    AddConfig "onReset.046d.c29a" ""
    AddConfig "onReset.046d.c29b" ""
    AddConfig "onReset.046d.c261" ""
    AddConfig "onReset.046d.c262" ""

}

# Start the program
Start()
{
    if ! IsRunning; then
        echo "Starting $PROGRAM"
        UpdateConfig
        $PROGRAM -b -c $CONFIG -r $LOGFILE
    fi
    return 0
}

# Stop the program
Stop()
{
    if IsRunning; then
        echo "Stopping $PROGRAM"
        kill `pidof $PROGRAM`
    fi
    return 0
}

# Print the current status of the program
Status()
{
    if IsRunning; then
        echo "$PROGRAM is running"
        return 0
    else
        echo "$PROGRAM is stopped"
        return 1
    fi
}

#
# main script
#
case "$1" in
    start)
        Start
        ;;
    stop)
        Stop
        ;;
    status)
        Status
        ;;
    *)
        echo "Usage: $0 [start|stop|status]" >&2
        exit 2
        ;;
esac
