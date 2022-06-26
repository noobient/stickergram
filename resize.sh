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
    \rm -rf "${resi_dir}"
    mkdir -p "${resi_dir}"
}

function enum_imgs ()
{
    imgs=("${orig_dir}/"*.png)
    imgs+=("${orig_dir}/"*.webp)
}

function print_imgs ()
{
    for (( i=0; i<${#imgs[@]} ; i++ ))
    do
        echo ${imgs[i]}
    done
}

clear_dir
enum_imgs
resize_pngs "${resi_dir}" "${imgs[@]}"
