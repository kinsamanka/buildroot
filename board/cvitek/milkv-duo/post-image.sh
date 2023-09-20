#!/bin/sh -e

BOARD_DIR="$(dirname $0)"

PATH=${PWD}/board/cvitek/common:$PATH
SRC=${PWD}/board/cvitek/common/fsbl

fiptool.py genfip ${BINARIES_DIR}/fip.bin \
    --MONITOR_RUNADDR=0x80000000 \
    --CHIP_CONF=${SRC}/chip_conf.bin \
    --NOR_INFO=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF \
    --NAND_INFO=00000000 \
    --BL2=${SRC}/bl2.bin \
    --BLCP_IMG_RUNADDR=0x05200200 \
    --BLCP_PARAM_LOADADDR=0 \
    --DDR_PARAM=${SRC}/ddr_param.bin \
    --MONITOR=${BINARIES_DIR}/fw_dynamic.bin \
    --LOADER_2ND=${BINARIES_DIR}/u-boot.bin

fn=$(grep BR2_TARGET_OPENSBI_ADDITIONAL_VARIABLES ${BR2_CONFIG} | cut -f2 -d")" | cut -f 1 -d '"' )

cp ${BUILD_DIR}/${fn} ${BINARIES_DIR}
cp ${PWD}/board/cvitek/milkv-duo/multi.its ${BINARIES_DIR}

lzma -fk ${BINARIES_DIR}/Image

mkimage -f ${BINARIES_DIR}/multi.its ${BINARIES_DIR}/boot.sd

support/scripts/genimage.sh -c ${BOARD_DIR}/genimage.cfg

gzip -fk ${BINARIES_DIR}/milkv-duo_sdcard.img
