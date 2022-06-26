#!/bin/bash

set -eu

if [ $# -ne 1 ]
then
    echo 'You must specify sticker set ID!'
    exit 1
fi

set_id=$1
l2t_dir=$(dirname $(realpath "${BASH_SOURCE}"))
. "${l2t_dir}/globals.sh"

function clear_dir ()
{
    \rm -rf "${conv_dir}"
    mkdir -p "${conv_dir}"
}

function enum_imgs ()
{
    imgs=("${resi_dir}/"*.webp)

    # only install anim_dump if we actually have webp files
    if [ ${#imgs[@]} -gt 0 ]
    then
        setup_animdump
    fi

    imgs+=("${resi_dir}/"*.png)
}

function print_imgs ()
{
    for (( i=0; i<${#imgs[@]} ; i++ ))
    do
        echo ${imgs[i]}
    done
}

function convert_imgs ()
{
    batch_size=$(nproc)
    echo "Starting batch conversion on ${batch_size} threads... "
    j=0
    set +e

    (
    for (( i=0; i<${#imgs[@]} ; i++ ))
    do
        ((j=j%batch_size)); ((j++==0)) && wait
        img_file=$(basename "${imgs[i]}")
        convert_img_webm "${imgs[i]}" "${conv_dir}/${img_file%.*}.webm" &
    done
    wait
    )

    set -e
    echo -e "\nBatch conversion done."
}

clear_dir
enum_imgs
#print_imgs
convert_imgs
