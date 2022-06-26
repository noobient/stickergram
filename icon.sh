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
    \rm -rf ${icon_dir}
    mkdir -p "${icon_dir}"
}

function check_config ()
{
    if [ $# -eq 2 ]
    then
        export pack_icon="${2}"
        echo "export pack_icon='${pack_icon}'" > "${icon_config}"
    elif [ -f "${icon_config}" ]
    then
        . "${icon_config}"
    fi

    if [ -z ${pack_icon+x} ]
    then
        echo 'Sticker ID preference not found, please specify both sticker pack ID and sticker ID!'
        exit 1
    fi
}

function resize_icon ()
{
    echo -n "Resizing icon... "
    resize_png "${resi_dir}/${1}.png" "${icon_dir}/${1}.png" '100x100' true
    echo ""
}

function convert_icon ()
{
    echo -n "Converting icon... "
    convert_img_webm "${icon_dir}/${1}.png" "${icon_dir}/${1}.webm"
    echo ""
}

clear_dir
check_config "${@}"
resize_icon "${pack_icon}"
convert_icon "${pack_icon}"
