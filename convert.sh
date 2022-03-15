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

function enum_pngs ()
{
    pngs=("${resi_dir}/"*.png)
}

function print_pngs ()
{
    for (( i=0; i<${#pngs[@]} ; i++ ))
    do
        echo ${pngs[i]}
    done
}

function convert_pngs ()
{
    batch_size=$(nproc)
    echo "Starting batch conversion on ${batch_size} threads... "
    j=0
    set +e

    (
    for (( i=0; i<${#pngs[@]} ; i++ ))
    do
        ((j=j%batch_size)); ((j++==0)) && wait
        png_file=$(basename "${pngs[i]}")
        convert_png "${pngs[i]}" "${conv_dir}/${png_file%.*}.webm" &
    done
    wait
    )

    set -e
    echo -e "\nBatch conversion done."
}

clear_dir
enum_pngs
#print_pngs
convert_pngs
