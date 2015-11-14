#!/bin/bash

function createJSONFile {
    local target=$1
    local basename=$2
    cat <<EOF >${target}
{
    "images": [
        {
            "idiom": "universal",
            "scale": "1x",
            "filename": "${basename}.png"
        },{
            "idiom": "universal",
            "scale": "2x",
            "filename": "${basename}@2x.png"
        },{
            "idiom": "universal",
            "scale": "3x",
            "filename": "${basename}@3x.png"
        }
    ],
    "info": {
        "version": 1,
        "author": "xcode"
    }
}
EOF
}

scriptsDir=$(dirname "${BASH_SOURCE[0]}")
rootDir=$(dirname "${scriptsDir}")

src=${HOME}/Developer/Resources/MAm-WeatherIcons-TV02e/icons
dst=${rootDir}/ScotTraffic/Assets.xcassets/weather

rm -rf ${dst}
mkdir -p ${dst}

set -x

for f in ${src}/PNGs_64x64/*.png; do
    base="`basename $f .png`"
    imageset="${dst}/${base}.imageset"

    mkdir -p "${imageset}"
    cp -f "${src}/PNGs_64x64/${base}.png" "${imageset}/${base}.png"
    cp -f "${src}/PNGs_64x64/${base}.png" "${imageset}/${base}@2x.png"
    cp -f "${src}/PNGs_128x128/${base}.png" "${imageset}/${base}@3x.png"
    sips -z 32 32 "${imageset}/${base}.png" >/dev/null
    sips -z 96 96 "${imageset}/${base}@3x.png" >/dev/null
    createJSONFile "${imageset}/Contents.json" "${base}"
done

