#
# This class is used to create Android device compatible boot.img files with kernel and initrd
# It differs from meta-android/classes/kernel_android.bbclass because it uses mkboot
#

do_compile[depends] += "initramfs-android-image:do_rootfs"
DEPENDS += "mkbootimg-tools-native"

do_compile_append() {
    cd ${B}
    cp ${WORKDIR}/img_info .
    sed -i "s@%%KERNEL%%@${B}/${KERNEL_OUTPUT}@" img_info
    sed -i "s@%%RAMDISK%%@${DEPLOY_DIR_IMAGE}/initramfs-android-image-${MACHINE}.cpio.gz@" img_info
    mkboot . boot.img
}

do_install_append() {
    install -d ${D}/${KERNEL_IMAGEDEST}
    install -m 0644 ${B}/boot.img ${D}/${KERNEL_IMAGEDEST}
}

do_deploy_append() {
    cp ${B}/boot.img ${DEPLOYDIR}/${KERNEL_IMAGE_BASE_NAME}.fastboot
    ln -sf ${KERNEL_IMAGE_BASE_NAME}.fastboot ${DEPLOYDIR}/${KERNEL_IMAGE_SYMLINK_NAME}.fastboot
}

pkg_postinst_kernel-image_append () {
    if [ x"$D" = "x" ] ; then
        if [ ! -e /boot/boot.img ] ; then
            # if the boot image is not available here something went wrong and we don't
            # continue with anything that can be dangerous
            exit 1
        fi

        BOOT_PARTITION_NAMES="LNX boot KERNEL"
        for i in $BOOT_PARTITION_NAMES; do
            path=$(find /dev -name "*$i*"|grep disk| head -n 1)
            [ -n "$path" ] && break
        done

        if [ -z "$path" ] ; then
            echo "Boot partition does not exist!"
            exit 1
        fi

        echo "Flashing the new kernel /boot/boot.img to $path"
        dd if=/boot/boot.img of=$path
    else
        exit 1
    fi
}

FILES_kernel-image += "/${KERNEL_IMAGEDEST}/boot.img"

