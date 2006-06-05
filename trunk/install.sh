#!/bin/sh
# -*- sh -*-
# vim:ft=sh:ts=8:sw=4:noet

[ -z "$PREFIX" ]        && PREFIX=/usr/local
[ -z "$EXEC_PREFIX" ]   && EXEC_PREFIX=$PREFIX

[ -z "$SCRIPT_DEST" ]   && SCRIPT_DEST=$BASE_DIR$EXEC_PREFIX/sbin/hibernate
[ -z "$SCRIPTLET_DIR" ] && SCRIPTLET_DIR=$BASE_DIR$PREFIX/share/hibernate/scriptlets.d
[ -z "$MAN_DIR" ]       && MAN_DIR=$BASE_DIR$PREFIX/man
[ -z "$CONFIG_DIR" ]    && CONFIG_DIR=${BASE_DIR}${CONFIG_PREFIX}/etc/hibernate
[ -z "$CONFIG_FILE" ]   && CONFIG_FILE=$CONFIG_DIR/hibernate.conf
[ -z "$RAM_CONFIG_FILE" ]    && RAM_CONFIG_FILE=$CONFIG_DIR/ram.conf
[ -z "$DISK_CONFIG_FILE" ]   && DISK_CONFIG_FILE=$CONFIG_DIR/disk.conf
[ -z "$S2_CONFIG_FILE" ]     && S2_CONFIG_FILE=$CONFIG_DIR/suspend2.conf
[ -z "$COMMON_CONFIG_FILE" ] && COMMON_CONFIG_FILE=$CONFIG_DIR/common.conf
[ -z "$BLACKLIST" ]     && BLACKLIST=$CONFIG_DIR/blacklisted-modules
[ -z "$LOGROTATE_DIR" ] && LOGROTATE_DIR=${BASE_DIR}/etc/logrotate.d

[ -z "$OLD_SCRIPTLET_DIR" ] && OLD_SCRIPTLET_DIR=$CONFIG_DIR/scriptlets.d

# Test if the script is already installed.
if [ -d $CONFIG_DIR ] || [ -f $SCRIPT_DEST ] ; then
    echo "Config directory $CONFIG_DIR and/or $SCRIPT_DEST already exist."
    echo -n "Are you sure you want to overwrite them? (y/N) "
    read REPLY
    echo
    case $REPLY in
	y*|Y*) ;;
	*) echo "Aborting!" ; exit 1 ;;
    esac
fi

(
set -e

echo "Installing hibernate script to $SCRIPT_DEST ..."
mkdir -p `dirname $SCRIPT_DEST`
cp -a hibernate.sh $SCRIPT_DEST

echo "Installing configuration files to $CONFIG_DIR ..."
mkdir -p $CONFIG_DIR
# We assume that if hibernate.conf does not exist, no config files do.
# Let a package management system figure this one out :)
if [ -f $CONFIG_FILE ] ; then
    echo "  **"
    echo "  ** You already have a configuration file at $CONFIG_FILE"
    echo "  ** The new version will be installed to ${CONFIG_FILE}.dist"
    echo "  **"
    cp -a hibernate.conf ${CONFIG_FILE}.dist
    cp -a ram.conf ${RAM_CONFIG_FILE}.dist
    cp -a disk.conf ${DISK_CONFIG_FILE}.dist
    cp -a suspend2.conf ${S2_CONFIG_FILE}.dist
    cp -a common.conf ${COMMON_CONFIG_FILE}.dist
    EXISTING_CONFIG=1
else
    cp -a hibernate.conf $CONFIG_FILE
    cp -a ram.conf $RAM_CONFIG_FILE
    cp -a disk.conf ${DISK_CONFIG_FILE}
    cp -a suspend2.conf ${S2_CONFIG_FILE}
    cp -a common.conf ${COMMON_CONFIG_FILE}
fi

cp -a blacklisted-modules $BLACKLIST

# Test if they have anything in there, and warn them
if /bin/ls $OLD_SCRIPTLET_DIR/* > /dev/null 2>&1 ; then
    echo "  **"
    echo "  ** You have scriptlets already installed in $OLD_SCRIPTLET_DIR"
    echo "  ** Since version 0.95, these have moved to $SCRIPTLET_DIR."
    echo "  ** If you are upgrading from a version prior to 0.95, you will"
    echo "  ** need to empty the contents of $OLD_SCRIPTLET_DIR manually!"
    echo "  **"
fi

echo "Installing scriptlets to $SCRIPTLET_DIR ..."
mkdir -p $SCRIPTLET_DIR
for i in scriptlets.d/* ; do
    cp -a $i $SCRIPTLET_DIR
done

if [ -d "$LOGROTATE_DIR" ] ; then
    LOGROTATE_TARGET=$LOGROTATE_DIR/hibernate-script
    echo "Installing logrotate file for hibernate.log to $LOGROTATE_TARGET ..."
    cp -a logrotate.d-hibernate-script $LOGROTATE_TARGET
    [ `whoami` = "root" ] && chown root:root $LOGROTATE_TARGET && chmod 644 $LOGROTATE_TARGET
fi

echo "Installing man pages to $MAN_DIR ..."
mkdir -p $MAN_DIR/man5 $MAN_DIR/man8
bash gen-manpages.sh
cp hibernate.conf.5 $MAN_DIR/man5
cp hibernate.8 $MAN_DIR/man8
rm -f hibernate.conf.5 hibernate.8

chmod 644 $MAN_DIR/man5/hibernate.conf.5 $MAN_DIR/man8/hibernate.8
[ `whoami` = "root" ] && chown root:root $MAN_DIR/man5/hibernate.conf.5 $MAN_DIR/man8/hibernate.8

echo "Setting permissions on installed files ..."
chmod 755 $SCRIPT_DEST $CONFIG_DIR
[ `whoami` = "root" ] && chown root:root -R $SCRIPT_DEST $CONFIG_DIR

echo "Installed."
echo
if [ -z "$EXISTING_CONFIG" ] ; then
    echo "Edit $CONFIG_FILE to taste, and see `basename $SCRIPT_DEST` -h for help."
else
    echo "You may want to merge $CONFIG_FILE with"
    echo "$CONFIG_FILE.dist"
    echo "See `basename $SCRIPT_DEST` -h for help on any extra options."
fi



)

[ $? -ne 0 ] && echo "Install aborted due to errors."

exit 0

# $Id$
