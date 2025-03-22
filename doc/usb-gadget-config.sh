#!/bin/bash

# 全部的usb gadget配置文件 
# 1. adb
# 2. uvc （可实现多uvc）
# 3. rndis
# 4. ums （用于OTA升级）

RNDIS_EN=off
ADB_EN=on
UVC_1_EN=off
UVC_2_EN=on
UMS_EN=off
ACM_EN=off
# 若不开启app，则需要开启ispserver
IRIS_APP_EN=off

MANUFACTURER="test-m"
VENDOR_ID=0x1234
PRODUCT_ID=0x5678
PRODUCT_NAME="test"

UVC_1_WIDTH=1080
UVC_1_HEIGHT=1920
UVC_1_SUB_COUNT=2   # 宽高向下缩的次数
UVC_1_DEVICE_NAME="${PRODUCT_NAME}(Col)"

UVC_2_WIDTH=1920
UVC_2_HEIGHT=1080
UVC_2_SUB_COUNT=0
UVC_2_DEVICE_NAME="${PRODUCT_NAME}(Nir)"

UMS_BLOCK=/userdata/ums_shared.img
UMS_BLOCK_SIZE=512	#unit M
UMS_BLOCK_TYPE=fat
UMS_BLOCK_AUTO_MOUNT=off
UMS_RO=0

RNDIS_ADDR=172.16.110.6

if [ -e "/tmp/.usb_adb_en" ] || [ -e "/oem/.usb_adb_en" ]; then
  ADB_EN=on
fi

USB_FUNCTIONS_DIR=/sys/kernel/config/usb_gadget/rockchip/functions
USB_CONFIGS_DIR=/sys/kernel/config/usb_gadget/rockchip/configs/b.1

configure_uvc_resolution_yuyv()                                  
{                                                                 
    UVC_DISPLAY_W=$1                                              
    UVC_DISPLAY_H=$2                                              
    UVC_NAME=$3                                                   
    mkdir ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u/${UVC_DISPLAY_H}p
    echo $UVC_DISPLAY_W > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u/${UVC_DISPLAY_H}p/wWidth
    echo $UVC_DISPLAY_H > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u/${UVC_DISPLAY_H}p/wHeight
    echo 2500000 > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u/${UVC_DISPLAY_H}p/dwDefaultFrameInterval
    echo $((UVC_DISPLAY_W*UVC_DISPLAY_H*20)) > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u/${UVC_DISPLAY_H}p/dwMinBitRate
    echo $((UVC_DISPLAY_W*UVC_DISPLAY_H*20)) > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u/${UVC_DISPLAY_H}p/dwMaxBitRate
    echo $((UVC_DISPLAY_W*UVC_DISPLAY_H*2)) > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u/${UVC_DISPLAY_H}p/dwMaxVideoFrameBufferSize
    echo -e "2500000\n5000000" > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u/${UVC_DISPLAY_H}p/dwFrameInterval                       
}


configure_uvc_resolution_mjpeg()
{
    UVC_DISPLAY_W=$1
    UVC_DISPLAY_H=$2
    UVC_NAME=$3
    mkdir ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m/${UVC_DISPLAY_H}p
    echo $UVC_DISPLAY_W > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m/${UVC_DISPLAY_H}p/wWidth
    echo $UVC_DISPLAY_H > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m/${UVC_DISPLAY_H}p/wHeight
    echo 1000000 > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m/${UVC_DISPLAY_H}p/dwDefaultFrameInterval
    echo $((UVC_DISPLAY_W*UVC_DISPLAY_H*20)) > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m/${UVC_DISPLAY_H}p/dwMinBitRate
    echo $((UVC_DISPLAY_W*UVC_DISPLAY_H*20)) > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m/${UVC_DISPLAY_H}p/dwMaxBitRate
    echo $((UVC_DISPLAY_W*UVC_DISPLAY_H*2)) > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m/${UVC_DISPLAY_H}p/dwMaxVideoFrameBufferSize
    echo -e "1000000\n2000000" > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m/${UVC_DISPLAY_H}p/dwFrameInterval
}

uvc_device_config()
{
    TUVC_DISPLAY_W=$1
    TUVC_DISPLAY_H=$2
    UVC_NAME=$3
    COUNT=$4

    mkdir ${USB_FUNCTIONS_DIR}/${UVC_NAME}
    
    # if [ "${TUVC_DISPLAY_W}" -gt "1080" ];then
    #   echo 1 > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/uvc_type
    # folution_mjpeg

    echo 3072 > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming_maxpacket
    echo 2 > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/uvc_num_request
    echo 0 > ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming_bulk

    mkdir ${USB_FUNCTIONS_DIR}/${UVC_NAME}/control/header/h
    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/control/header/h ${USB_FUNCTIONS_DIR}/${UVC_NAME}/control/class/fs/h
    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/control/header/h ${USB_FUNCTIONS_DIR}/${UVC_NAME}/control/class/ss/h
    
    ##mjpeg support config
    mkdir ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m
    mkdir ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u
    #configure_uvc_resolution_mjpeg/yuyv ${UVC_DISPLAY_W} ${UVC_DISPLAY_H} ${UVC_NAME}
    for (( i=$COUNT; i>=0; i-- ))                                                                                                                  
    do                                                                                                                                             
        w=$((TUVC_DISPLAY_W / (1<<i)))                                                                                                             
        h=$((TUVC_DISPLAY_H / (1<<i)))                                                                                                             
        echo ${w} ${h} $((1<<i)) ${TUVC_DISPLAY_W} ${TUVC_DISPLAY_H}                                                                               
        configure_uvc_resolution_yuyv ${w} ${h} ${UVC_NAME}                                                                                       
    done

    for (( i=$COUNT; i>=0; i-- ))                                                                                                                  
    do                                                                                                                                             
        w=$((TUVC_DISPLAY_W / (1<<i)))                                                                                                             
        h=$((TUVC_DISPLAY_H / (1<<i)))                                                                                                             
        echo ${w} ${h} $((1<<i)) ${TUVC_DISPLAY_W} ${TUVC_DISPLAY_H}                                                                               
        configure_uvc_resolution_mjpeg ${w} ${h} ${UVC_NAME}                                                                                       
    done                   


    mkdir ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/header/h
    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/mjpeg/m ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/header/h/m
    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/uncompressed/u ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/header/h/u
#    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/framebased/f1 ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/header/h/f1
#    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/framebased/f2 ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/header/h/f2
    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/header/h ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/class/fs/h
    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/header/h ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/class/hs/h
    ln -s ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/header/h ${USB_FUNCTIONS_DIR}/${UVC_NAME}/streaming/class/ss/h
}

pre_run_adb()
{
    umount /dev/usb-ffs/adb
    mkdir -p /dev/usb-ffs/adb -m 0770
    mount -o uid=2000,gid=2000 -t functionfs adb /dev/usb-ffs/adb
    # ifconfig lo up # 快启版本需要设置这个才有用
    start-stop-daemon --start --quiet --background --exec /usr/bin/adbd
}

rndis_config()
{
    # config rndis
    mkdir ${USB_FUNCTIONS_DIR}/rndis.gs0
    # echo "uvc_rndis" > ${USB_CONFIGS_DIR}/strings/0x409/configuration
    ln -s ${USB_FUNCTIONS_DIR}/rndis.gs0 ${USB_CONFIGS_DIR}/f5
    echo "config uvc and rndis..."
}

pre_run_rndis()
{
    echo "config usb0 IP... " $RNDIS_ADDR
    ifconfig usb0 $RNDIS_ADDR
    ifconfig usb0 up
}

ums_config()
{
    mkdir ${USB_FUNCTIONS_DIR}/mass_storage.0

    echo ${UMS_RO} > ${USB_FUNCTIONS_DIR}/mass_storage.0/lun.0/ro
    if [ "$UMS_BLOCK_SIZE" != "0" -a ! -e ${UMS_BLOCK} ]; then
        dd if=/dev/zero of=${UMS_BLOCK} bs=1M count=${UMS_BLOCK_SIZE}
        mkfs.${UMS_BLOCK_TYPE} ${UMS_BLOCK}
        test $? && echo "Warning: failed to mkfs.${UMS_BLOCK_TYPE} ${UMS_BLOCK}"
    fi
    if [ $UMS_BLOCK_AUTO_MOUNT = on ];then
        mount ${UMS_BLOCK} /mnt/
    else
        echo ${UMS_BLOCK} > ${USB_FUNCTIONS_DIR}/mass_storage.0/lun.0/file
    fi

    ln -s ${USB_FUNCTIONS_DIR}/mass_storage.0 ${USB_CONFIGS_DIR}/f6
}

run_binary()
{
    if [ $IRIS_APP_EN = on ];then
        /oem/iris_face_dev &
    fi

    if [ $UVC_1_EN = on ] || [ $UVC_2_EN = on ];then
        if [ $IRIS_APP_EN != on ];then
            ispserver -n &
            sleep .5
        fi
    fi

    if [ $RNDIS_EN = on ];then
        pre_run_rndis
    fi

    if [ $UVC_1_EN = on ];then
        /oem/uvc_ap -v /dev/video31 &
    fi

    if [ $UVC_2_EN = on ];then
        /oem/uvc_app  -v /dev/video39 &
    fi
}

##main
#init usb config
#/etc/init.d/S10udev stop
umount /sys/kernel/config
mkdir /dev/usb-ffs
mount -t configfs none /sys/kernel/config
mkdir -p /sys/kernel/config/usb_gadget/rockchip
mkdir -p /sys/kernel/config/usb_gadget/rockchip/strings/0x409
mkdir -p ${USB_CONFIGS_DIR}/strings/0x409
echo $VENDOR_ID > /sys/kernel/config/usb_gadget/rockchip/idVendor
echo 0x0310 > /sys/kernel/config/usb_gadget/rockchip/bcdDevice
echo 0x0200 > /sys/kernel/config/usb_gadget/rockchip/bcdUSB
echo 239 > /sys/kernel/config/usb_gadget/rockchip/bDeviceClass
echo 2 > /sys/kernel/config/usb_gadget/rockchip/bDeviceSubClass
echo 1 > /sys/kernel/config/usb_gadget/rockchip/bDeviceProtocol

SERIAL_NUM=`cat /proc/cpuinfo | grep Serial | awk '{print $3}'`
echo "serialnumber is $SERIAL_NUM"
echo $SERIAL_NUM > /sys/kernel/config/usb_gadget/rockchip/strings/0x409/serialnumber
echo $MANUFACTURER > /sys/kernel/config/usb_gadget/rockchip/strings/0x409/manufacturer
echo $PRODUCT_NAME > /sys/kernel/config/usb_gadget/rockchip/strings/0x409/product
echo 0x1 > /sys/kernel/config/usb_gadget/rockchip/os_desc/b_vendor_code
echo "MSFT100" > /sys/kernel/config/usb_gadget/rockchip/os_desc/qw_sign
echo 500 > /sys/kernel/config/usb_gadget/rockchip/configs/b.1/MaxPower
#ln -s /sys/kernel/config/usb_gadget/rockchip/configs/b.1 /sys/kernel/config/usb_gadget/rockchip/os_desc/b.1
echo $PRODUCT_ID > /sys/kernel/config/usb_gadget/rockchip/idProduct

echo $PRODUCT_NAME > ${USB_CONFIGS_DIR}/strings/0x409/configuration
echo "config " $PRODUCT_NAME " ..."

if [ $RNDIS_EN = on ];then
    rndis_config
fi

if [ $ACM_EN = on ];then
    mkdir ${USB_FUNCTIONS_DIR}/acm.gs6
    ln -s ${USB_FUNCTIONS_DIR}/acm.gs6 ${USB_CONFIGS_DIR}/f7
fi

#uvc config init
if [ $UVC_1_EN = on ];then
    uvc_device_config $UVC_1_WIDTH $UVC_1_HEIGHT uvc.gs6 $UVC_1_SUB_COUNT
    echo $UVC_1_DEVICE_NAME > ${USB_FUNCTIONS_DIR}/uvc.gs6/device_name 
    ln -s ${USB_FUNCTIONS_DIR}/uvc.gs6 ${USB_CONFIGS_DIR}/f1
fi

if [ $UVC_2_EN = on ];then
    uvc_device_config $UVC_2_WIDTH $UVC_2_HEIGHT uvc.gs7 $UVC_2_SUB_COUNT 
    echo $UVC_2_DEVICE_NAME > ${USB_FUNCTIONS_DIR}/uvc.gs7/device_name 
    ln -s ${USB_FUNCTIONS_DIR}/uvc.gs7 ${USB_CONFIGS_DIR}/f2
fi

if [ $ADB_EN = on ];then
    mkdir ${USB_FUNCTIONS_DIR}/ffs.adb
    ln -s ${USB_FUNCTIONS_DIR}/ffs.adb ${USB_CONFIGS_DIR}/f4
    pre_run_adb
    sleep .5
fi

if [ $UMS_EN = on ];then
    ums_config
fi

UDC=`ls /sys/class/udc/| awk '{print $1}'`
echo $UDC > /sys/kernel/config/usb_gadget/rockchip/UDC

run_binary
