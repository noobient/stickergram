#!/bin/bash

set -eu

if [ $# -lt 1 ]
then
    echo 'You must specify sticker pack ID!'
    exit 1
fi

set_id=$1
l2t_dir=$(dirname $(realpath "${BASH_SOURCE}"))
. "${l2t_dir}/globals.sh"

function clear_dir ()
{
    \rm -rf "${conv_dir}"
    \rm -rf "${trim_dir}"
    \rm -rf "${resi_dir}"
    \rm -rf "${fuzz_dir}"
    mkdir -p "${conv_dir}"
    mkdir -p "${trim_dir}"
    mkdir -p "${resi_dir}"
    mkdir -p "${fuzz_dir}"
}

function convert_jpgs ()
{
    for (( i=0; i<${#jpgs[@]} ; i++ ))
    do
        jpg_file=$(basename "${jpgs[i]}")
        echo -n "Converting ${jpg_file}... "
        convert_jpg "${jpgs[i]}" "${conv_dir}/${jpg_file%.*}.png"
        echo "done."
    done
}

function trim_pngs ()
{
    for (( i=0; i<${#pngs[@]} ; i++ ))
    do
        png_file=$(basename "${pngs[i]}")
        echo -n "Trimming ${png_file}... "
        convert "${pngs[i]}" -fuzz 1% -trim "${trim_dir}/${png_file}"
        echo "done."
    done
}

function fuzz_pngs ()
{
    local i
    for (( i=0; i<${#pngs[@]} ; i++ ))
    do
        png_file=$(basename "${pngs[i]}")
        fuzz_png "${pngs[i]}" "${fuzz_dir}"
    done
}

clear_dir

jpgs=("${orig_dir}/"*.jpg)
# make sure to only run if files are actually there
find "${orig_dir}/" -name *.jpg -type f | grep . && convert_jpgs
find "${orig_dir}/" -name *.png -type f | grep . && cp "${orig_dir}/"*.png "${conv_dir}"

pngs=("${conv_dir}/"*.png)
trim_pngs

pngs=("${trim_dir}/"*.png)
fuzz_pngs

pngs=("${fuzz_dir}/"*.png)
resize_pngs "${resi_dir}" "${pngs[@]}"
