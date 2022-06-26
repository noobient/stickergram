export dist_dir="${l2t_dir}/dist/${set_id}"
export orig_dir="${dist_dir}/orig"
export resi_dir="${dist_dir}/resi"
export conv_dir="${dist_dir}/conv"
export icon_dir="${dist_dir}/icon"
export trim_dir="${dist_dir}/trim"
export fuzz_dir="${dist_dir}/fuzz"
export icon_config="${dist_dir}/icon.conf"
export page_file="${orig_dir}/page.html"
export fuzz_cap=20

export tool_dir="${l2t_dir}/tool"
export webp_dir="${tool_dir}/libwebp"
export webp_version='1.2.2'
export PATH="${PATH}:${webp_dir}/examples"

shopt -s nullglob

function get_pack_type ()
{
    echo $(cat "${page_file}" | pup --plain 'div[data-widget-id=MainSticker] attr{data-preview}' | jq -r '.type')
}

function print_pack_type ()
{
    echo -n "Determining pack type... "
    get_pack_type
}


function get_pack_name ()
{
    echo $(cat "${page_file}" | pup --plain 'p[data-test="sticker-name-title"] text{}')
}

function print_pack_name ()
{
    echo -n "Determining pack name... "
    get_pack_name
}

# returns 'apng' for animated, 'png_pipe' for static
function get_img_type ()
{
    echo $(ffprobe -hide_banner -loglevel 0 -print_format json -show_format "${1}" | jq -r '.format.format_name')
}

function print_png_type ()
{
    echo -n "Determining PNG type... "
    get_img_type
}

function is_transparent_png ()
{
    echo $(identify -format '%A\n' ${1})
}

# $1: source PNG file
# $2: target PNG file
# $3: size in NxN format
# $4: if true, pad to precise size (required for pack icons)
function resize_png ()
{
    if [ ! -z "${4+x}" ] && [ ${4} = true ]
    then
        convert_extra_flags=" -gravity center -background none -extent ${3}"
    else
        convert_extra_flags=''
    fi

    png_type=$(get_img_type "${1}")

    case ${png_type} in
        apng)
            png_file=$(basename "${1}")
            target_dir=$(dirname "${2}")
            temp_dir="${target_dir}/${png_file}-temp"

            mkdir "${temp_dir}"
            pushd "${temp_dir}" > /dev/null

            \rm -f *
            cp "${1}" .
            apngdis "${png_file}" > /dev/null
            echo -en "\e[36m${png_file}\e[0m:\e[35munpacked\e[0m "
            \rm -f "${png_file}"

            for j in *.png
            do
                convert "${j}" -resize "${3}" ${convert_extra_flags} "${j}"
            done
            echo -en "\e[36m${png_file}\e[0m:\e[34mresized\e[0m "

            apngasm "${png_file}" apngframe*.png > /dev/null
            echo -en "\e[36m${png_file}\e[0m:\e[32mrepacked\e[0m "
            cp --no-target-directory "${png_file}" "${2}"

            popd > /dev/null
            \rm -rf "${temp_dir}"
            ;;

        png_pipe|webp_pipe)
            convert "${1}" -resize "${3}" ${convert_extra_flags} "${2}"
            echo -en "\e[36m $(basename ${1})\e[0m:\e[32mresized\e[0m "
            ;;

        *)
            exit 1
    esac
}

# $1: target dir
# $2: array of PNG file full paths
# TODO maybe use source dir for $2 to avoid messy arrays?
function resize_pngs ()
{
    # gotta rebuild param array manually
    target_dir="${1}"
    shift
    pngs=("$@")

    batch_size=$(nproc)
    echo "Starting batch resize on ${batch_size} threads... "
    j=0
    set +e

    (
    for (( i=0; i<${#pngs[@]} ; i++ ))
    do
        ((j=j%batch_size)); ((j++==0)) && wait
        resize_png "${pngs[i]}" "${target_dir}/$(basename "${pngs[i]}")" '512x512' &
    done
    wait
    )

    set -e
    echo -e "\nBatch resize done."
}

function setup_animdump
{
    have_animdump=0
    which anim_dump && have_animdump=1 || true

    if [ ${have_animdump} -eq 1 ]
    then
        return
    fi

    echo 'Setting up anim_dump...'
    mkdir -p "${tool_dir}"

    echo 'Obtaining libwebp sources...'
    git clone --quiet https://github.com/webmproject/libwebp.git "${webp_dir}"

    pushd "${webp_dir}" > /dev/null

    git fetch --all --tags --quiet
    git checkout --quiet "tags/v${webp_version}"

    echo 'Running libwebp autogen.sh...'
    BUILD_ANIMDIFF=1 ./autogen.sh > /dev/null
    echo 'Configuring libwebp...'
    ./configure --enable-libwebpdecoder --enable-libwebpextras > /dev/null
    echo 'Building libwebp...'
    make -j$(nproc) > /dev/null

    popd > /dev/null

    echo 'anim_dump setup done.'
}

# $1: source PNG or WebP file
# $2: target WEBM file
function convert_img_webm ()
{
    png_type=$(get_img_type "${1}")

    case ${png_type} in
        apng)
            png_file=$(basename "${1}")
            ffmpeg -i "${1}" -b:v 512k "${2}" 2> /dev/null
            echo -en "\e[36m${png_file}\e[0m:\e[32mdone\e[0m "
            ;;

        png_pipe)
            echo -en "\e[36m $(basename ${1})\e[0m:\e[31mskipping\e[0m "
            ;;

        webp_pipe)
            webp_file=$(basename "${1}")
            target_dir=$(dirname "${2}")
            temp_dir="${target_dir}/${webp_file}-temp"

            \rm -rf "${temp_dir}"
            mkdir "${temp_dir}"

            anim_dump -folder "${temp_dir}" "${1}" > /dev/null
            echo -en "\e[36m${webp_file}\e[0m:\e[35munpacked\e[0m "

            # settled with these numbers after some trial-n-error
            # might need to adjust them later
            ffmpeg -framerate 19 -i "${temp_dir}/dump_%04d.png" -b:v 512k "${2}" 2> /dev/null
            echo -en "\e[36m${webp_file}\e[0m:\e[32mdone\e[0m "

            \rm -rf "${temp_dir}"
            ;;

        *)
            exit 1
    esac
}

function convert_jpg ()
{
    convert "${1}" "${2}"
}

# $1: source PNG file
# $2: target dir
function fuzz_png ()
{
    png_file=$(basename "${1}")
    local i

    batch_size=$(nproc)
    echo -n "Fuzzing ${png_file} with ${batch_size} threads... "
    j=0
    set +e

    (
    for (( i=1; i<=${fuzz_cap} ; i++ ))
    do
        ((j=j%batch_size)); ((j++==0)) && wait
        color=$(convert "${1}" -format "%[pixel:p{0,0}]" info:-) && \
        convert "${1}" -alpha off -bordercolor $color -border 1 \
        \( +clone -fuzz "${i}%" -fill none -floodfill +0+0 $color -alpha extract -geometry 200% -blur 0x0.5 -morphology erode square:1 -geometry 50% \) \
        -compose CopyOpacity -composite -shave 1 \
        "${2}/${png_file%.*}_fuzz$(printf "%02d" ${i}).png" &
    done
    wait
    )
    set -e
    echo "done."
}
