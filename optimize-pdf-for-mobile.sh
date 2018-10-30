#!/usr/bin/env bash

# optimize-pdf-for-mobile.sh
#
# Optimize PDF for mobile
# Designed for iOS & PDFKit
#
# Giorgos Sgouridis - 26.10.2018
#    Latest Version - 30.10.2018
#
# This script: https://github.com/gsgou/optimize-pdf-for-mobile

SCRIPT_VERSION=1.0.0

if [[ $1 == "-V" || $1 == "--version" ]]; then
    echo "$(basename "$0") v$SCRIPT_VERSION"
	exit 0
fi

if [[ ! -e $1 ]]; then
    echo "ERROR: Please specify input file"
    exit 1
fi

FILE=$1

FILE_DIR="$(dirname "${FILE}")/"
FILE_NAME="$(basename "${FILE}" | cut -d. -f1)"

MAXRES_DEFAULT="47200000"
MAXRES=${2:-$MAXRES_DEFAULT}

VERSION_DEFAULT=1.7
VERSION=$(pdfinfo "$FILE" | grep "PDF version" | sed 's/[^0-9]*//')

NEEDS_OPTIMIZATION=false

COMPATIBILITYLEVEL_ARG=
if [ "$(bc <<< "$VERSION == $VERSION_DEFAULT")" -eq 0 ]; then
    NEEDS_OPTIMIZATION=true
    COMPATIBILITYLEVEL_ARG="-dCompatibilityLevel=$VERSION_DEFAULT"
fi

# if -dFastWebView isn't set the file created will be by default not optimized for web
if [ "$(pdfinfo "$FILE" | grep "Optimized" | sed 's/[^YyNn]*//')" = no ]; then
    NEEDS_OPTIMIZATION=true
fi

PAGE_SCALE_ARRAY=()
IMAGES_TO_RESIZE=()
METAS=$(pdfimages -list "$FILE" | tail -n +3 | tr -s " " | tr " " "," | cut -d, -f2,3,5,6)

for META in ${METAS[@]}; do

  PAGE=$(echo "$META" | cut -f1 -d",")
  #NUM=$(echo "$META" | cut -f2 -d",")
  WIDTH=$(echo "$META" | cut -f3 -d",")
  HEIGHT=$(echo "$META" | cut -f4 -d",")
  RES=$((WIDTH*HEIGHT))
  SCALE=$(awk "BEGIN {printf \"%.2f\",${MAXRES_DEFAULT}/${RES}}")
  SCALE=$(echo "sqrt ( $SCALE )" | bc -l)

  if [ $RES -gt "$MAXRES" ]; then
      PAGE_SCALE_ARRAY+=( "$PAGE"-"$SCALE" )
      IMAGES_TO_RESIZE+=("Page $PAGE, Res $((WIDTH*HEIGHT))")
  fi

done

if [ ${#PAGE_SCALE_ARRAY[@]} -ne 0 ]; then
    NEEDS_OPTIMIZATION=true
fi

if [ "$NEEDS_OPTIMIZATION" == false ]; then
    echo "No optimization required"
    exit 0
fi

# Gets image size using pdfimages
get_image_size()
{
    local QUERY="$(pdfimages -list "$1" | tail -n +3 | tr -s " " | tr " " "," | cut -d, -f14,15 | tr "," " ")"
 
    if [ -z "$QUERY" ]; then
        return 1
    fi

    # Make it an array
    QUERY=($QUERY)
        
    IMAGE_WIDTH=$(printf '%.0f' "${QUERY[0]}")
    #IMAGE_HEIGHT=$(printf '%.0f' "${QUERY[1]}")

    return 0
}

# Gets page size using pdfinfo
get_page_size()
{
    local QUERY="$(pdfinfo "$1" 2>/dev/null | grep -i 'Page size:')"
 
    if [ -z "$QUERY" ]; then
        return 1
    fi
        
    # Remove stuff
    QUERY="${QUERY##*Page size:}"
    # Make it an array
    QUERY=($QUERY)
        
    PAGE_WIDTH=$(printf '%.0f' "${QUERY[0]}")
    PAGE_HEIGHT=$(printf '%.0f' "${QUERY[2]}")

    return 0
}

# Runs GS call for resizing
gs_page_resize()
{
    # Change page size
    gs \
    -dSAFER \
    -dNOPAUSE \
    -dQUIET \
    -dBATCH \
    -sDEVICE=pdfwrite \
    -dCompatibilityLevel="1.7" \
    -dDownsampleColorImages=true \
    -dDownsampleGrayImages=true \
    -dDownsampleMonoImages=true \
    -dColorImageResolution="$1" \
    -dGrayImageResolution="$1" \
    -dMonoImageResolution="$1" \
    -dColorImageDownsampleType=/Bicubic \
    -dGrayImageDownsampleType=/Bicubic \
    -dMonoImageDownsampleType=/Bicubic \
    -dColorImageDownsampleThreshold=1.0 \
    -dGrayImageDownsampleThreshold=1.0 \
    -dMonoImageDownsampleThreshold=1.0 \
    -dColorConversionStrategy=/LeaveColorUnchanged \
    -dDEVICEWIDTHPOINTS="$2" \
    -dDEVICEHEIGHTPOINTS="$3" \
    -sOutputFile="$OUTFILE_PDF" \
    -f "$INFILE_PDF"
    return $?
}

if [ ${#PAGE_SCALE_ARRAY[@]} -ne 0 ]; then
    echo "Pages found with image resolution over $MAXRES:"
    ( IFS=$'\n'; echo "${IMAGES_TO_RESIZE[*]}" )

    TO_RESIZE_FOLDER="PagesToResize/"
    mkdir -p $FILE_DIR$TO_RESIZE_FOLDER
    pdfseparate $FILE $FILE_DIR$TO_RESIZE_FOLDER$FILE_NAME-page_%d.pdf

    for set in ${PAGE_SCALE_ARRAY[@]}; do

    PAGE_IN_ARRAY=${set%%-*}
    SCALE_IN_ARRAY=${set##*-}

    get_page_size $FILE_DIR$TO_RESIZE_FOLDER$FILE_NAME-page_$PAGE_IN_ARRAY.pdf
    get_image_size $FILE_DIR$TO_RESIZE_FOLDER$FILE_NAME-page_$PAGE_IN_ARRAY.pdf
    IMAGE_RESOLUTION=$(awk "BEGIN {printf \"%.0f\",${IMAGE_WIDTH}*${SCALE_IN_ARRAY}}")
    RESIZE_WIDTH=$(awk "BEGIN {printf \"%.0f\",${PAGE_WIDTH}*${SCALE_IN_ARRAY}}")
    RESIZE_HEIGHT=$(awk "BEGIN {printf \"%.0f\",${PAGE_HEIGHT}*${SCALE_IN_ARRAY}}")
    OUTFILE_PDF=$FILE_DIR$TO_RESIZE_FOLDER$FILE_NAME-page_$PAGE_IN_ARRAY-resized.pdf
    INFILE_PDF=$FILE_DIR$TO_RESIZE_FOLDER$FILE_NAME-page_$PAGE_IN_ARRAY.pdf

    gs_page_resize "$IMAGE_RESOLUTION" "$RESIZE_WIDTH" "$RESIZE_HEIGHT"
    mv $OUTFILE_PDF $INFILE_PDF
    
    done
fi

PDFS_TO_UNITE="$(find $FILE_DIR$TO_RESIZE_FOLDER*_*.pdf | sort -V)"
FILE_RESIZED="$FILE_DIR$FILE_NAME-resized.pdf"
pdfunite $PDFS_TO_UNITE $FILE_RESIZED
rm -rf $FILE_DIR$TO_RESIZE_FOLDER

# Ghostscript arguments
# -dCompatibilityLevel=1.7 generates a PDF version 1.7
# -dSAFER to prevent unsafe PostScript operations which can allow an attacker to execute arbitrary commands with arbitrary arguments
# -dBATCH -dNOPAUSE will process the input file without interaction and quit on completion
# -dQUIET mutes routine information comments on standard output
FILE_OPTIMIZED="$FILE_DIR$FILE_NAME-optimized.pdf"
declare -a cmdArgs='([0]="gs"\
                     [1]="-dSAFER"\
                     [2]="-dNOPAUSE"\
                     [3]="-dQUIET"\
                     [4]="-dBATCH"\
                     [5]="-sDEVICE=pdfwrite"\
                     [6]="$COMPATIBILITYLEVEL_ARG"\
                     [8]="-dFastWebView"\
                     [9]="-sOutputFile=$FILE_OPTIMIZED"\
                     [10]="$FILE_RESIZED")'

# Removing null elements from array
for i in "${!cmdArgs[@]}"
do
    [ -n "${cmdArgs[$i]}" ] || unset "cmdArgs[$i]"
done

# Reindexing
cmdArgs=("${cmdArgs[@]}")
                                
# Execute the optimization
"${cmdArgs[@]}" &> /dev/null

if [ $? -ne 0 ]; then
  echo "ERROR: Ghostscript"
  exit 1
fi

rm -f "$FILE_RESIZED"

FILE_OPTIMIZED_SIZE=$(stat -f "%z" "${FILE_OPTIMIZED}")
if [ "${FILE_OPTIMIZED_SIZE}" -eq 0 ]; then
    echo "ERROR: Ghostscript, no output."
    rm -f "${FILE_OPTIMIZED}"
    exit 1
fi

FILE_SIZE=$(stat -f "%z" "${FILE}")
if [ "${FILE_OPTIMIZED_SIZE}" -le "${FILE_SIZE}" ]; then
    BYTES_SAVED=$((FILE_SIZE - FILE_OPTIMIZED_SIZE))
    PERCENT=$((FILE_OPTIMIZED_SIZE * 100 / FILE_SIZE))
    echo Reduced the file size by "$BYTES_SAVED" bytes \(now "${PERCENT}"% of the original pdf\)
fi