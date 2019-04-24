#!/bin/bash

VBOXMANAGE="/usr/bin/vboxmanage"
BACKUPFOLDER="/home/backup/local"
snapname="";
destFolder="";

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
chmod -R 700 $BACKUPFOLDER;
if [ ! -d $destFolder ];
then
    mkdir -p $destFolder;
fi;
$VBOXMANAGE clonevm $machine --snapshot $snapname --basefolder="$destFolder"
}



function copyMachineFiles
{
machine=$1;
entriesCount=`cat /tmp/.vm.hdfiles | wc -l`
i=0;
curdate=`date '+%Y-%m-%d_%H%M%S'`
echo "[$machine] [$curdate] Backup [$entriesCount] machine files...";
DATA=`date '+%Y-%m-%d_%H%M'`
while read fileline; do
    let i=i+1;
    machinefile=`echo $fileline  | awk 'BEGIN {FS="="}{print $2}' | sed 's#\"##g'`
    machinefilesize=`ls -lh "$machinefile" | awk '{print $5}'`
    destFileName=`echo ${machinefile##*/}`

    curdate=`date '+%Y-%m-%d_%H%M%S'`
    echo "[$machine] [$curdate] Backup [$i/$entriesCount] files:  [$machinefile] [$machinefilesize]";

    cp "$machinefile" "$destFolder";

    curdate=`date '+%Y-%m-%d_%H%M%S'`
    echo "[$machine] [$curdate] Copied to: $destFolder";

done < /tmp/.vm.hdfiles

}
function backupMachineFiles
{
machine=$1;
curdate=`date '+%Y-%m-%d_%H%M%S'`

echo "[$machine] [$curdate] Searching hd files...";
if [ -f /tmp/.vm.hdfiles ]; then
rm /tmp/.vm.hdfiles
fi;
$VBOXMANAGE showvminfo $machine --machinereadable | grep "vdi\|CfgFile" > /tmp/.vm.hdfiles

copyMachineFiles $machine
}


function backupMachine
{
machine=$1;
doMachineSnapshot $machine
cloneMachineSnapshot $machine
backupMachineFiles $machine
echo "Done backup: [$machine]";
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



getVmList
iterateMachines
