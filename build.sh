#!/bin/bash

DEVICE=$1

make-config()
{
	if [ "$DEVICE" = "flat" ]; then
		echo "Make S7 Flat defconfig."
		make exynos8890-herolte_defconfig
	elif [ "$DEVICE" = "edge" ]; then
		echo "Make S7 Edge defconfig."
		make exynos8890-hero2lte_defconfig
	fi
}

make-dtb()
{
	if [ "$DEVICE" = "flat" ]; then
		echo "Make S7 Flat DeviceTree image."
		tools/dtbtool -o dt-flat.img -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/
	elif [ "$DEVICE" = "edge" ]; then
		echo "Make S7 Edge DeviceTree image."
		tools/dtbtool -o dt.img -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/
	fi
}

make-boot()
{
	if [ "$DEVICE" = "flat" ]; then
		echo "Make S7 Flat Boot image."
		mkbootimg \
			--kernel arch/arm64/boot/Image \
			--ramdisk ramdisk.packed \
			--base 0x10000000 \
			--pagesize 2048 \
			--dt dt-flat.img \
			--ramdisk_offset 0x01000000 \
			--tags_offset 0x00000100 \
			--output boot-flat.img
		echo -n "SEANDROIDENFORCE" >> boot-flat.img
		tar -cvf boot-flat.tar boot-flat.img
	elif [ "$DEVICE" = "edge" ]; then
		echo "Make S7 Edge Boot image."
		mkbootimg \
			--kernel arch/arm64/boot/Image \
			--ramdisk ramdisk.packed \
			--base 0x10000000 \
			--pagesize 2048 \
			--dt dt.img \
			--ramdisk_offset 0x01000000 \
			--tags_offset 0x00000100 \
			--output boot.img
		echo -n "SEANDROIDENFORCE" >> boot.img
		tar -cvf boot.tar boot.img
	fi
}

if [ ! -n "$1" ]; then
	echo "No argument, Select S7 Edge as default."
	DEVICE="edge"
fi

if [ "$DEVICE" = "flat" ] || [ "$DEVICE" = "edge" ]; then
	export ARCH=arm64

	export PATH=/home/devries/aarch64-linux-gnu-5.3:$PATH

	export PATH=/home/devries/GitHub/mkbootimg_tools:$PATH

	export CROSS_COMPILE=/home/devries/aarch64-linux-gnu-5.3/bin/aarch64-

	make-config

	make -j7 2>&1 |tee build.txt

	rm arch/arm64/boot/dts/*.dtb

	make dtbs

	make-dtb

	make-boot
else
	echo "Invalid argument, Input 'edge' or 'flat'."
fi