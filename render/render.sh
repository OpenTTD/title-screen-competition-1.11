#!/bin/sh

set -ex

render_path=$(realpath $(dirname ${0}))
patch=${render_path}/openttd-render.patch
palette=${render_path}/palette.png

# Ensure we have a patched and compiled OpenTTD binary.
if [ ! -e ${render_path}/OpenTTD ]; then
	(
		cd ${render_path}
		git clone --depth 1 https://github.com/OpenTTD/OpenTTD

		cd OpenTTD
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
cd ${render_path}/OpenTTD/build

(
	for res in "1024x768" "1280x1024" "1440x900" "1920x1080" "2560x1440"; do
		echo "::group::Render screenshots (${res})"
		rm -f screenshot/*
		# Run OpenTTD to create a screenshot per tick.
		./openttd -D -b 8bpp-optimized -x -c empty.cfg -g ${savegame} -r ${res}
		echo "::endgroup::"

		filename=$(echo ${screens_path}/${prefix}-$(echo ${res} | sed s/x/_/))

		(
			cd screenshot
			cp tick_000.png ${filename}.png

			if [ "${res}" != "1920x1080" ] && [ "${res}" != "2560x1440" ]; then
				# Convert the screenshots to GIFs for lower resolutions (to keep the filesize ~10MB).
				echo "::group::Animated GIF (${res})"
				ffmpeg -framerate 33.33 -i tick_%03d.png -i ${palette} -filter_complex "fps=33.33[x];[x][1:v]paletteuse" -y ${filename}.gif
				echo "::endgroup::"
			fi

			# Convert the screenshots to mp4s for all resolutions, but a bit lossy; this to keep the filesize ~10MB.
			echo "::group::Movie (${res})"
			ffmpeg -framerate 33.33 -i tick_%03d.png -filter_complex "fps=33.33" -crf 28 -pix_fmt yuv420p -y ${filename}.mp4
			echo "::endgroup::"
		)
	done
)

rm -f screenshot/*
