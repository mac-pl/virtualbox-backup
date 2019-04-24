#!/bin/bash

VBOXMANAGE="/usr/bin/vboxmanage"
BACKUPFOLDER="/mnt/backup/"
snapname="";

function getVmList {

$VBOXMANAGE list vms | awk '{ print $1}' | sed 's#\"##g' > /tmp/vm.list

}




function doMachineSnapshot
{
machine=$1;
mname=`echo $machine | sed 's# #_#g'`
dateVal=`date +%Y_%m_%d_%H%M%S`
snapname=$mname"-"$dateVal;
$VBOXMANAGE snapshot $machine take $snapname
}

function cloneMachineSnapshot
{
machine=$1;
destFolder=$BACKUPFOLDER"/"$machine"/"$snapname;
if [ ! -d $destFolder ];
then
    mkdir -p $destFolder;
fi;
$VBOXMANAGE clonevm $machine --snapshot $snapname --basefolder=$destFolder
}


function backupMachineFiles
{
machine=$1;
curdate=`date '+%Y-%m-%d_%H%M%S'`

echo "[$machine] [$curdate] Searching hd files...";
if [ -f /tmp/.vm.hdfiles ]; then
rm /tmp/.vm.hdfiles
fi;
vboxmanage showvminfo $machine --machinereadable | grep "vdi\|CfgFile" > /tmp/.vm.hdfiles

copyMachineFiles $machine
}

function copyMachineFiles
{
entriesCount=`cat /tmp/.vm.hdfiles | wc -l`
i=0;
curdate=`date '+%Y-%m-%d_%H%M%S'`
echo "[$1] [$curdate] Backup [$ile] machine files...";
DATA=`date '+%Y-%m-%d_%H%M'`
folder="$1_$DATA";
while read fileline; do
    let i=i+1;
    machinefile=`echo $fileline  | awk 'BEGIN {FS="="}{print $2}' | sed 's#\"##g'`
    machinefilesize=`ls -lh "$machinefile" | awk '{print $5}'`
    destFileName=`echo ${machinefile##*/}`
    if [ ! -d $BACKUPFOLDER/$folder ];
    then
        mkdir -p $BACKUPFOLDER/$folder
    fi;

    curdate=`date '+%Y-%m-%d_%H%M%S'`
    echo "[$1] [$curdate] Backup [$i/$entriesCount] files:  [$machinefile] [$machinefilesize]";

    cp "$machinefile" "$BACKUPFOLDER/$folder/$destFileName";

    curdate=`date '+%Y-%m-%d_%H%M%S'`
    echo "[$machine] [$curdate] Copied to: $BACKUPFOLDER/$folder/$destFileName";

done < /tmp/.vm.hdfiles

}

function doMachineBackup
{
machine=$1;
echo "Machine: [$machine] backup started";
if [ "$machine" == "" ];
then
    echo "Skip machine [$machine]";
    return;
fi;

backupMachine $machine
echo "";
}

function iterateMachines
{
while read machine; do
    doMachineBackup $machine
done < /tmp/vm.list
}

function backupMachine
{
machine=$1;
doMachineSnapshot $machine
cloneMachineSnapshot $machine
backupMachineFiles $machine
echo "Done backup: [$machine]";
}



getVmList
iterateMachines
