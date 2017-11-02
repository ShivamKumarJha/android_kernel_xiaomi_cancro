#!/bin/bash
###########################################################################
# Bash Color
blink_red='\033[05;31m'
red=$(tput setaf 1) 		  # red
green=$(tput setaf 2)             # green
cyan=$(tput setaf 6) 		  # cyan
txtbld=$(tput bold)               # Bold
bldred=${txtbld}$(tput setaf 1)   # red
bldgrn=${txtbld}$(tput setaf 2)   # green
bldblu=${txtbld}$(tput setaf 4)   # blue
bldcya=${txtbld}$(tput setaf 6)   # cyan
restore=$(tput sgr0)              # Reset
clear

###########################################################################
# Resources
THREAD="-j12"
KERNEL="zImage"
DTBIMAGE="dt.img"
DEFCONFIG="cancro_user_defconfig"
device="cancro"
COMPILER_TYPE="arm-linux-androideabi"
COMPILER_VERSION="4.9"
COMPILER="$PWD/../$COMPILER_TYPE-$COMPILER_VERSION/bin"

###########################################################################
# Vars
export CROSS_COMPILE="$COMPILER/$COMPILER_TYPE-"
export ARCH=arm
export SUBARCH=arm
export KBUILD_BUILD_USER="cancro"
export KBUILD_BUILD_HOST="rebase"
ZIP_NAME="cancro_rebase"

set -e

# Paths
STRIP=$COMPILER/$COMPILER_TYPE-strip
KERNEL_DIR=$PWD
REPACK_DIR="$KERNEL_DIR/zip/temp/kernel_zip"
# https://github.com/xiaolu/mkbootimg_tools
DTBTOOL_DIR="$KERNEL_DIR/mkbootimg_tools"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm/boot"

# Functions

function make_dtb {
		$DTBTOOL_DIR/dtbToolCM -2 -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm/boot/

}
function clean_all {
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG $THREAD "| tee -a log"
		cp -vr $ZIMAGE_DIR/$KERNEL $REPACK_DIR/zImage
}

function make_zip {
		cd $REPACK_DIR
		zip -r ~/kernel/builds/$ZIP_NAME-$(date +%d-%m_%H%M).zip *
}

function copy_modules {
		echo "Copying modules"
		find . -name '*.ko' -exec cp {} $REPACK_DIR/modules/ \;
		echo "Stripping modules for size"
		$STRIP --strip-unneeded $REPACK_DIR/modules/*.ko
}

DATE_START=$(date +"%s")

echo -e "${bldred}"; echo -e "${blink_red}"; echo "$AK_VER"; echo -e "${restore}";

echo -e "${bldgrn}"
echo "-----------------"
echo "Making Cancro Rebase Kernel:"
echo "-----------------"
echo -e "${restore}"

echo -e "${bldgrn}"
while read -p "Do you want to clean stuff (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done
echo -e "${restore}"
echo
echo -e "${txtbld}"
while read -p "Do you want to build kernel (y/n)? " dchoice
echo -e "${restore}"
do
case "$dchoice" in
	y|Y)
		make_kernel 
		if [ -e "arch/arm/boot/zImage" ]; then
		make_dtb 
		copy_modules
		make_zip
		else
		echo -e "${bldred}"
		echo "Kernel Compilation failed, zImage not found"
		echo -e "${restore}"
		exit 1
		fi
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done
echo -e "${bldgrn}"
echo "$ZIP_NAME-$(date +%d-%m_%H%M).zip"
echo -e "${bldred}"
echo "################################################################################"
echo -e "${bldgrn}"
echo "------------------------Cancro rebase compiled in:------------------------------"
echo -e "${bldred}"
echo "################################################################################"
echo -e "${restore}"

DIFF=$(($(date + "%s") - $DATE_START))
echo -e "${bldblu}"
echo $DIFF
