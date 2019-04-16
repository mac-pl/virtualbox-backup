#!/bin/bash

VBOXMANAGE="/usr/bin/vboxmanage"
BACKUPFOLDER="/mnt/backup/"
snapname="";

function getVmList {

$VBOXMANAGE list vms | awk '{ print $1}' | sed 's#\"##g' > /tmp/vm.list

}


function waitForMachineShutDown
{
while true; do
isRunning=`$VBOXMANAGE showvminfo "$1" | grep -c "running (since"`
if [ $isRunning -eq 0 ]; then
    echo "";
    echo "Stopped";
    return;
fi;
echo -n ".";
sleep 1;
done;
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


function backupMachine
{
machine=$1;
doMachineSnapshot $machine
cloneMachineSnapshot $machine
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
