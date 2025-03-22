# CMakeList.txt: CMakeProject3 的 CMake 项目，在此处包括源代码并定义
# 项目特定的逻辑。
#
cmake_minimum_required (VERSION 3.8)

project(uvc_gadget)

# SET(CMAKE_FIND_ROOT_PATH /mnt/f/work/c++/gcc/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf)
# SET(CMAKE_C_COMPILER   ${CMAKE_FIND_ROOT_PATH}/bin/arm-linux-gnueabihf-gcc)
# SET(CMAKE_CXX_COMPILER ${CMAKE_FIND_ROOT_PATH}/bin/arm-linux-gnueabihf-g++)

add_definitions(-std=c++11 -mfpu=neon -fpermissive)
#添加配置 
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(GCC_COMPILER_VERSION "" CACHE STRING "GCC Compiler version")
set(GNU_MACHINE "arm-linux-gnueabi" CACHE STRING "GNU compiler triple")

# 设置交叉编译器环境
SET(CMAKE_FIND_ROOT_PATH /mnt/f/work/linaro/arm)
SET(CMAKE_C_COMPILER   ${CMAKE_FIND_ROOT_PATH}/bin/arm-linux-gnueabi-gcc)
SET(CMAKE_CXX_COMPILER ${CMAKE_FIND_ROOT_PATH}/bin/arm-linux-gnueabi-g++)

SET(CMAKE_C_FLAGS_RELEASE " -O3")
SET(CMAKE_CXX_FLAGS_RELEASE " -O3")

set(CMAKE_BUILD_TYPE "Release")

include_directories(.)

add_executable (uvc_app uvc-gadget.c)
target_link_libraries(
    uvc_app ${APP_DEPENDENTS} dl
)



# TODO: 如有需要，请添加测试并安装目标。
