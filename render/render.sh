#!/bin/sh

set -ex

render_path=$(realpath $(dirname ${0}))
patch=${render_path}/openttd-render.patch
palette=${render_path}/palette.png

# Ensure we have a patched and compiled OpenTTD binary.
if [ ! -e ${render_path}/OpenTTD ]; then
	(
		cd ${render_path}
		# Needed while #8804 is not merged yet.
		#git clone https://github.com/OpenTTD/OpenTTD
		git clone https://github.com/TrueBrain/OpenTTD

		cd OpenTTD
		git checkout screenshot-resolution
		patch -p1 < ${patch}
	)
fi
if [ ! -e ${render_path}/OpenTTD/build ]; then
	(
		cd ${render_path}/OpenTTD
		mkdir build

		cd build
		cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr -DOPTION_DEDICATED=ON
		make -j$(nproc)
	)
fi

if [ -z "${2}" ]; then
	if [ "${1}" = "--prepare" ]; then
		exit 0
	fi

	echo "Usage: $0 <savegame> <destionation>"
	exit 1
fi

savegame=$(realpath ${1})
screens_path=$(realpath ${2})
prefix=$(echo $(basename ${1}) | sed s/.sav$//)

mkdir -p ${screens_path}

echo "::group::Create screenshots"
cd ${render_path}/OpenTTD/build
rm -f screenshot/*
# Run OpenTTD to create a screenshot per tick.
./openttd -D -b 8bpp-optimized -x -c empty.cfg -g ${savegame}
echo "::endgroup::"

(
	cd screenshot
	# Convert the screenshots to GIFs for lower resolutions (to keep the filesize ~10MB).
	for res in "1024:768" "1280:1024" "1440:900"; do
		filename=$(echo ${screens_path}/${prefix}-$(echo ${res} | sed s/:/_/))
		echo "::group::Animated GIF (${res})"
		ffmpeg -framerate 33.33 -i tick_%03d_2560_1440.png -i ${palette} -filter_complex "fps=33.33[x];[x]crop=${res}:0:0[y];[y][1:v]paletteuse" -y ${filename}.gif
		echo "::endgroup::"
	done

	# Convert the screenshots to mp4s for all resolutions, but a bit lossy; this to keep the filesize ~10MB.
	for res in "1024:768" "1280:1024" "1440:900" "1920:1080" "2560:1440"; do
		filename=$(echo ${screens_path}/${prefix}-$(echo ${res} | sed s/:/_/))
		echo "::group::Movie (${res})"
		ffmpeg -framerate 33.33 -i tick_%03d_2560_1440.png -filter_complex "fps=33.33[x];[x]crop=${res}:0:0" -crf 28 -pix_fmt yuv420p -y ${filename}.mp4
		ffmpeg -i ${filename}.mp4 -i ${palette} -vframes 1 -f image2 -filter_complex "[0:v]paletteuse" -y ${filename}.png
		echo "::endgroup::"
	done
)
