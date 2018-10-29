#!/usr/bin/env bash

# optimize-pdf-for-mobile.sh
#
# Optimize PDF for mobile
# Considered iOS & PDFKit
#
# Giorgos Sgouridis - 26.10.2018
#    Latest Version - 29.10.2018
#
# This script: https://github.com/gsgou/optimize-pdf-for-mobile

SCRIPT_VERSION=1.0.0

if [[ $1 == "-V" || $1 == "--version" ]]; then
    echo "$(basename $0) v$SCRIPT_VERSION"
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

IMAGES_TO_RESIZE=()
METAS=$(pdfimages -list "$FILE" | tail -n +3 | tr -s " " | tr " " "," | cut -d, -f2,3,5,6)

for META in ${METAS[@]}; do

  PAGE=$(echo "$META" | cut -f1 -d",")
  NUM=$(echo "$META" | cut -f2 -d",")
  WIDTH=$(echo "$META" | cut -f3 -d",")
  HEIGHT=$(echo "$META" | cut -f4 -d",")
  RES=$((WIDTH*HEIGHT))

  if [ $RES -gt "$MAXRES" ]; then
      IMAGES_TO_RESIZE+=("Page $PAGE, Num $NUM, Res $((WIDTH*HEIGHT))")
  fi

done

PDFSETTINGS_ARG=
if [ ${#IMAGES_TO_RESIZE[@]} -ne 0 ]; then
    NEEDS_OPTIMIZATION=true
    # 300 dpi images, color preserving
    #PDFSETTINGS_ARG=-dPDFSETTINGS=/prepress
    echo "Images that need to be resized:"
    ( IFS=$'\n'; echo "${IMAGES_TO_RESIZE[*]}" )
fi

if [ "$NEEDS_OPTIMIZATION" == false ]; then
    exit 0
fi

# Ghostscript arguments
# -dCompatibilityLevel=1.7 generates a PDF version 1.7
# -dBATCH -dNOPAUSE will process the input file without interaction and quit on completion
# -dQUIET mutes routine information comments on standard output

FILE_OPTIMIZED="$FILE_DIR$FILE_NAME-optimized.pdf"
declare -a cmdArgs='([0]="gs"\
                     [1]="-sDEVICE=pdfwrite"\
                     [2]="$COMPATIBILITYLEVEL_ARG"\
		             [3]="$PDFSETTINGS_ARG"\
                     [4]="-dFastWebView"\
                     [5]="-dNOPAUSE"\
                     [6]="-dQUIET"\
                     [7]="-dBATCH"\
                     [8]="-sOutputFile=$FILE_OPTIMIZED"\
                     [9]="$FILE")'

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