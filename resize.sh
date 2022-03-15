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

function enum_pngs ()
{
    pngs=("${orig_dir}/"*.png)
}

function print_pngs ()
{
    for (( i=0; i<${#pngs[@]} ; i++ ))
    do
        echo ${pngs[i]}
    done
}

clear_dir
enum_pngs
resize_pngs "${resi_dir}" "${pngs[@]}"
