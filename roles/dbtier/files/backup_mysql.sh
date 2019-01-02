#!/bin/bash

# Script version: 1.0

# General vars
COMPRESSION_TYPE='BZ2' # GZIP / BZ2
DB_NAME='glpi'
DB_USER='root'
DB_PASS='s7p0rt3'
DB_PARAMS='--add-drop-table --add-locks --extended-insert --single-transaction -quick'
DATE=`date +%Y%m%d_%Hh%Mm`
BACKUP_DIR=/tmp/backup/mysql
BACKUP_NAME=bd_$DB_NAME-$DATE.sql
BACKUP_POLICY=+7 # Number of days to delete backup files from

# Step header vars
STEP_TITLE0="- Ensuring $BACKUP_DIR exists..."
STEP_TITLE1="- Dumping database $DB_NAME into $BACKUP_DIR/$BACKUP_NAME..."
STEP_TITLE2="- Compressing backup file ($COMPRESSION_TYPE)..."
STEP_TITLE3="- Deleting temp (.sql) file..."
STEP_TITLE4="- Applying backup policy (deleting $BACKUP_POLICY old files)..."
STEP_TITLE5="- Coping compressed file to Windows file server..."

# Remote/Windows vars
WIN_SERVER_MNT='/mnt/windows_backup'
REMOTE_SHARE='//serv26d/BACKUP/'
REMOTE_DIR='centraldeservicos'
CREDENTIAL='/var/backups/credentials'



# Functions
print_step_header() {
echo "
> STEP $STEP"

case "$STEP" in
  0) echo $STEP_TITLE0 ;;
  1) echo $STEP_TITLE1 ;;
  2) echo $STEP_TITLE2 ;;
  3) echo $STEP_TITLE3 ;;
  4) echo $STEP_TITLE4 ;;
  5) echo $STEP_TITLE5 ;;
  *) echo "- Non identified step" ;;
esac
}

verify_succeed() {
if [ ! $? -eq 0 ] ;
then
  echo "-- Failed on step $STEP
   "
  exit 1
fi
}


# Program body

# Print header
clear
echo "___________________________________________________________________"
echo " "
echo " Starting database backup - `date`"
echo "___________________________________________________________________"

# Ensure BACKUP_DIR exists (STEP 0)
STEP=0
print_step_header
if [ ! -e $BACKUP_DIR ]
then
  echo "-- $BACKUP_DIR does not exist. You must create it before runing this script."
  exit 1
fi

# Dump database (STEP 1)
let STEP=1
print_step_header
mysqldump $DB_NAME $DB_PARAMS -u $DB_USER -p$DB_PASS > $BACKUP_DIR/$BACKUP_NAME
verify_succeed

# Compress sql into gzip/bz2 (STEP 2)
let STEP=2
print_step_header
case "$COMPRESSION_TYPE" in
  GZIP)
    COMPRESSION_OPTIONS='-cvzf'
    BACKUP_COMPRESSED_NAME=bd_$DB_NAME-$DATE.tar.gz
    ;;
  BZ2)
    COMPRESSION_OPTIONS='-cvjf'
    BACKUP_COMPRESSED_NAME=bd_$DB_NAME-$DATE.tar.bz2
    ;;
esac
tar $COMPRESSION_OPTIONS $BACKUP_DIR/$BACKUP_COMPRESSED_NAME $BACKUP_DIR/$BACKUP_NAME
verify_succeed

# Delete temp file (.sql) (STEP 3)
let STEP=3
print_step_header
rm -rf $BACKUP_DIR/$BACKUP_NAME
verify_succeed

# Apply backup policy (STEP 4)
let STEP=4
print_step_header
find $BACKUP_DIR -type f -name "$DB_NAME*" -ctime $BACKUP_POLICY -exec rm -f {} ";"
verify_succeed


# Copy compressed file to Windows file server
# Must have $REMOTE_DIR directory created with write permission
let STEP=5
print_step_header
if [ ! -d "$WIN_SERVER_MNT" ] ;
then
  echo "-- Mounting remote..."
  mount.cifs $REMOTE_SHARE $WIN_SERVER_MNT --verbose -o credentials=$CREDENTIAL
  verify_succeed
fi

if [ ! -w "$WIN_SERVER_MNT/$REMOTE_DIR" ] ;
then
  echo "-- Credentials do not have write permission on $REMOTE_SHARE/$REMOTE_DIR!"
  exit 1
else
  echo "-- Preceeding copy..."
  cp -f $BACKUP_DIR/$BACKUP_COMPRESSED_NAME $WIN_SERVER_MNT/$REMOTE_DIR
  verify_succeed
fi

# Print footer
echo "___________________________________________________________________"
echo " "
echo " Successful backup - `date`"
echo "___________________________________________________________________"
echo " "

exit 0
