#!/bin/sh

function help( ) {
    echo "Usage: create-sdcard.sh --device /dev/XX"
    echo "Create a bootable uSD card for Rasperry PI"
    echo ""
    echo "Options:"
    echo "  --device dev  Identify the uSD card device (default is /dev/sdg)"
    exit 0
}

function do_exit( ) {
    echo "ERROR in line $1 !"
    exit 0
}

device='/dev/sdg'
kernel_only=0
update=0

if [ $# -ge 1 ]; then
    skip=0
    for i in $(seq 1 1 $#); do
        if [ $skip -eq 1 ]; then
            skip=0
            continue
        fi
        argn="${@:${i}:1}"
        case $argn in
            --help )
                help ;;
            --device )
                skip=1
                j=i+1
                device="${@:${j}:1}"
                ;;
            --update )
                update=1
                ;;
            --kernel-only )
                kernel_only=1
                ;;
        esac
    done
fi

if [ 'X/dev/sda' == 'X'$device ]; then
    echo 'This is likely the Hard-drive!!'
    exit 0
fi

if [ 'X' == 'X'$device ]; then
    help
fi

function fdisk_input( ) {
    echo -en 'd\n1\n'
    echo -en 'd\n2\n'
    echo -en 'd\n3\n'
    echo -en 'd\n4\n'
    echo -en 'n\np\n1\n2048\n+128M\n'
    echo -en 'n\np\n2\n\n\n'
    echo -en 't\n1\nc\n'
    echo -en 'w\n'
}

dd if=/dev/zero of=$device bs=1024 count=128
sudo partprobe ${device} || do_exit $LINENO
fdisk_input | fdisk $device > /dev/null
if [ $? != 1 ]; then
    echo 'fdisk seems to have failed'
    exit -1
fi
sudo partprobe ${device} || do_exit $LINENO
sync
sleep 2

# Format the partitions
mkfs.vfat -n BOOT ${device}1
mkfs.ext4 -F -L rootfs ${device}2

# Copy the firmware and kernel
sudo umount ${device}1
sudo umount ${device}2
rm -rf /tmp/LINUX_FROM_SCRATCH_*
TD=`mktemp -d /tmp/LINUX_FROM_SCRATCH_XXXXXX`
sudo mount ${device}1 $TD || do_exit $LINENO
sudo cp -r output/images/rpi-firmware/* $TD || do_exit $LINENO
sudo cp output/images/*.dtb $TD || do_exit $LINENO
sudo output/build/linux-rpi-4.9.y/scripts/mkknlimg output/images/Image $TD/Image || do_exit $LINENO

# Change configuration
sudo sed -i -e "s/kernel=zImage/kernel=Image/" ${TD}/config.txt
sudo sed -i -e "\$aarm_control=0x200" ${TD}/config.txt
sudo umount $TD 

# Copy the root filesystem
sudo mount ${device}2 $TD || do_exit $LINENO
sudo tar -x -f output/images/rootfs.tar -C $TD

# Done with the uSD card
sudo umount $TD 
rmdir $TD 
eject $device
