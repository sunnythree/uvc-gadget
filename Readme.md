**Upstream Latest Version: http://git.ideasonboard.org/uvc-gadget.git**

## uvc-gadget

**Upstream project [uvc-gadget](http://git.ideasonboard.org/uvc-gadget.git) has been updated and continuous maintenance**

UVC gadget userspace enhancement sample application

Fork from  
[uvc-gadget.git](http://git.ideasonboard.org/uvc-gadget.git)  
Apply enhancement Bhupesh Sharma's patchset  
[UVC gadget test application enhancements](https://www.spinics.net/lists/linux-usb/msg84376.html)  
and Robert Baldyga's patchset  
[Bugfixes for UVC gadget test application](https://www.spinics.net/lists/linux-usb/msg99220.html)  

## How to use

    Usage: ./uvc-gadget [options]
    
    Available options are
        -b             Use bulk mode
        -d             Do not use any real V4L2 capture device
        -f <format>    Select frame format
                0 = V4L2_PIX_FMT_YUYV
                1 = V4L2_PIX_FMT_MJPEG
        -h             Print this help screen and exit
        -i image       MJPEG image
        -m             Streaming mult for ISOC (b/w 0 and 2)
        -n             Number of Video buffers (b/w 2 and 32)
        -o <IO method> Select UVC IO method:
                0 = MMAP
                1 = USER_PTR
        -r <resolution> Select frame resolution:
                0 = 360p, VGA (640x360)
                1 = 720p, WXGA (1280x720)
        -s <speed>     Select USB bus speed (b/w 0 and 2)
                0 = Full Speed (FS)
                1 = High Speed (HS)
                2 = Super Speed (SS)
        -t             Streaming burst (b/w 0 and 15)
        -u device      UVC Video Output device
        -v device      V4L2 Video Capture device

## Build  

- host:  
    make
- Cross compile:  
    make ARCH=arch CROSS_COMPILE=cross_compiler  
    eg:  
    make ARCH=arm CROSS_COMPILE=arm-hisiv600-linux-  
- or:  
    set ARCH, CROSS_COMPILE, KERNEL_DIR in Makefile

## Change log

- Apply patchset [Bugfixes for UVC gadget test application](https://www.spinics.net/lists/linux-usb/msg99220.html)  

- Apply patchset [UVC gadget test application enhancements](https://www.spinics.net/lists/linux-usb/msg84376.html)  

- Add Readme/.gitignore and documentations  
  Copy linux-3.18.y/drivers/usb/gadget/function/uvc.h into repository, change include path for build

### Initial

- Fork(copy) from [uvc-gadget.git](http://git.ideasonboard.org/uvc-gadget.git)

### change
for my device, i changed:
1. in uvc_events_process_data function, add:
```
        if(dev->fcc == V4L2_PIX_FMT_YUYV){
            printf("stream on V4L2_PIX_FMT_YUYV\n");
        }else{
            printf("stream on V4L2_PIX_FMT_MJPEG\n");
        }
        printf("fcc width height: %d %d %d\n", dev->fcc, dev->width, dev->height);
        {
            if(!dev->is_streaming){
                printf("bulk stream on1\n");
                ret = uvc_handle_streamon_event(dev);
                printf("bulk stream on2 %d\n", ret);
            }else{
                printf("bulk stream has on\n");
            }

            if (ret < 0)
                goto err;
        }
```
because stream on event not triggered, if not add these code.

2. change payload_size = dev->imgsize; => payload_size = dev->width * dev->height * 2;
```
        case V4L2_PIX_FMT_MJPEG:
            // payload_size = dev->imgsize;
            payload_size = dev->width * dev->height * 2;
            break;
        }
```
because ret = ioctl(dev->uvc_fd, VIDIOC_QBUF, &buf); fail error with code (22), I do not understand why, 
but after i change like this, it work well.

I also add a config demo in doc/uvc-gadget-config.sh:
