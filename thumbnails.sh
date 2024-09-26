#!/usr/bin/env zsh

########################################################################################################
#
# bradmax thumbnails tool
# https://bradmax.com
#
# byMTHK
#
########################################################################################################

####################################################
# color const
####################################################
declare +i -r RED='\033[0;31m';
declare +i -r GREEN='\033[0;32m';
declare +i -r BLUE='\033[0;34m';
declare +i -r CYAN='\033[0;36m';
declare +i -r YELLOW='\033[0;33m';
declare +i -r DGRAY='\033[1;30m';
declare +i -r RESET='\033[0m';
####################################################
# print header
####################################################
print_header() {
	echo "${BLUE}####################################################";
	echo "  _                   _                      ";
	echo " | |                 | |                     ";
	echo " | |__  _ __ __ _  __| |_ __ ___   __ ___  __";
	echo " | '_ \| '__/ _\` |/ _\` | '_ \` _ \ / _\` \ \/ /";
	echo " | |_) | | | (_| | (_| | | | | | | (_| |>  < ";
	echo " |_.__/|_|  \__,_|\__,_|_| |_| |_|\__,_/_/\_\\";
	echo "                                             ";
	echo " ${CYAN}https://bradmax.com${RESET}          ";
	echo "                                             ";
	echo "${BLUE}####################################################${RESET}";
}

# RUN
#
print_header;

####################################################
# check if ffmpeg is available
####################################################
if [ -z "$(ffmpeg -version)" ]; then
	echo "\n${RED}ERROR: plaease install ffmpeg dependencie!${RESET} https://ffmpeg.org/download.html \n\n" 1>&2;
	exit 0;
fi
####################################################
# default input options
####################################################
declare -r +i IMG_EXT=jpg;
declare -r +i VTT_EXT=vtt;
declare -r -i FFMPEG_LOG_LEVEL=error;
declare -r -i SPRITESHEET_MODE=0; # 0 - spritesheets
declare -r -i THUMBNAILS_MODE=1; 	# 1 - separate thumbnails
declare -i MODE=$SPRITESHEET_MODE;
declare -i WIDTH=160; 		# in pixels
declare -i HEIGHT=0; 			# in pixels
declare -i GRID_SIZE=20; 	# in pixels
declare -i TIMESPAN=10; 	# in seconds
declare -i WITH_POSTER=0; # 0 - false 1 - true;
declare +i INPUT;
declare +i OUTPUT;
declare +i FILE_NAME;
declare +i POSTER_NAME;
declare +i IMG_DIR;
declare +i IMG_NAME;
declare +i VTT_NAME;
declare -i GENERATE_ROWS=6;
declare -i GENERATE_COLUMNS=5;

########################################################################################################
# HELPERS
########################################################################################################

void() {
	#pass
}

divide() {
	# divide && ceil
	echo $((($1 / $2) + ($1 % $2 > 0)));
}

########################################################################################################
# PRINT HELP
########################################################################################################

help() {
	echo "\n${GREEN} Arguments:$RESET";
	echo "  -spritesheets \t ${DGRAY}(optional)${RESET} Generate image sprites (default).";
	echo "  -thumbnails \t\t ${DGRAY}(optional)${RESET} Generate single image files instad image sprites.";
 	echo "  -poster \t\t ${DGRAY}(optional)${RESET} Generate poster image.";
	echo "  -i ${DGRAY}|${RESET} --input \t\t ${DGRAY}(required)${RESET} Path to video file.";
	echo "  -o ${DGRAY}|${RESET} --output \t ${DGRAY}(required)${RESET} Path to output directory.";
	echo "  -t ${DGRAY}|${RESET} --timespan \t ${DGRAY}(optional)${RESET} Time span (in seconds) between each thumbnail (default, ${TIMESPAN}).";
	echo "  -w ${DGRAY}|${RESET} --width \t\t ${DGRAY}(optional)${RESET} Width (in pixels) of each thumbnail (default ${WIDTH}).";
 	# echo "  -s ${DGRAY}|${RESET} --grid-size \t ${DGRAY}(optional)${RESET} Generated image sprite max grid size dimmention in pixels (default, ${GRID_SIZE}).";
 	echo "  -n ${DGRAY}|${RESET} --name \t\t ${DGRAY}(optional)${RESET} Base name for generated files, default 'spritesheet' when -spritesheets or 'thumbnail' when -thumbnails flag is enabled.";
 	echo "  --vtt-name \t\t ${DGRAY}(optional)${RESET} Override base name (-n) for VTT file. When provided generated vtt file path will be '[--output]/[--vtt-name].vtt'.";
 	echo "  --img-name \t\t ${DGRAY}(optional)${RESET} Override base name (-n) for image files. When provided generated images path will be '[--output]/[--img-name].jpg'.";
 	echo "  --img-dir \t\t ${DGRAY}(optional)${RESET} Base dir for image files. When provided generated images path will be '[--output]/[--img-dir]/[--(img-)name].jpg'.";
	echo "  --ss-cols \t\t ${DGRAY}(optional)${RESET} Number of image columns for spritesheets (default 6).";
	echo "  --ss-rows \t\t ${DGRAY}(optional)${RESET} Number of image rows for spritesheets (default 5).";
	echo "  -h ${DGRAY}|${RESET} --help \t\t ${DGRAY}(optional)${RESET} Displays this message.";
	echo "\n------------------------------------------------\n";
	echo "${GREEN} Usage: ${RESET} $ thumbnails.sh -i /input/video.mp4 -o /output/directory [-w <number>] [-t <number>] [-n <string>] [-r <number>] [-c <number>]${DGRAY}\n";
	echo "${BLUE}####################################################${RESET}\n";
}

########################################################################################################
# PARSE OPTIONS
########################################################################################################

####################################################
# parse input options
####################################################
while [[ "$#" -gt 0 ]]; do
	case "$1" in
		-spritesheets) MODE=$SPRITESHEET_MODE; shift;;
		-thumbnails) MODE=$THUMBNAILS_MODE; shift;;
		-poster) WITH_POSTER=1; shift;;
		-i | --input) INPUT="$2"; shift 2;;
		-o | --output) OUTPUT="$2"; shift 2;;
		-n | --name) FILE_NAME="$2"; shift 2;;
		-t | --timespan) TIMESPAN="$2"; shift 2;;
		-w | --width) WIDTH="$2"; shift 2;;
		# -s | --grid-size) GRID_SIZE="$2" shift 2;;
		--img-dir) IMG_DIR="$2"; shift 2;;
		--img-name) IMG_NAME="$2"; shift 2;;
		--vtt-name) VTT_NAME="$2"; shift 2;;
		--ss-cols) GENERATE_COLUMNS="$2"; shift 2;;
		--ss-rows) GENERATE_ROWS="$2"; shift 2;;
		-h | --help) help; exit 0;;
		--) shift; break;;
		*) help; echo "${RED}ERROR: Unexpected option: $1" 1>&2; exit 0;;
	esac
done

####################################################
# update file name
####################################################
if [[ -z "${FILE_NAME}" ]]; then
	if [ $MODE -eq $SPRITESHEET_MODE ]; then FILE_NAME="spritesheet"; fi
	if [ $MODE -eq $THUMBNAILS_MODE ]; then FILE_NAME="thumbnail"; fi
fi
if [[ -z "${IMG_NAME}" ]]; then IMG_NAME=$FILE_NAME; fi
if [[ -z "${VTT_NAME}" ]]; then VTT_NAME=$FILE_NAME; fi
####################################################
# check if input option is provided
####################################################
if [[ -z "${INPUT}" ]]; then
	help;
	echo "${RED}ERROR: --input (-i) option not provided${RESET}" 1>&2;
	exit 0;
fi
####################################################
# check if input is valid file
####################################################
if [[ -d "${INPUT}" ]]; then
	help;
	echo "${RED}ERROR: --input (-i) should be file not directory path${RESET}" 1>&2;
	exit 0;
fi
if [[ -f "${INPUT}" ]]; then void; else
	help;
	echo "${RED}ERROR: --input (-i) option not valid file path${RESET}" 1>&2;
	exit 0;
fi


####################################################
# check if output option is provided
####################################################
if [[ -z "${OUTPUT}" ]]; then
	help;
	echo "${RED}ERROR: --output (-o) option not provided${RESET}" 1>&2;
	exit 0;
fi
if [[ -f "${OUTPUT}" ]]; then
	help;
	echo "${RED}ERROR: --output (-o) should be directory path not file path${RESET}" 1>&2;
	exit 0;
fi
# if [[ -d "${OUTPUT}" ]]; then void; else
# 	help;
# 	echo "${RED}ERROR: --output (-o) option not valid directory path${RESET}" 1>&2;
# 	exit 0;
# fi
########################################################################################################
# PROBE
########################################################################################################

####################################################
# probe duration and fps data from video
####################################################
eval $(ffprobe -v $FFMPEG_LOG_LEVEL -show_format -of flat=s=_ -show_entries stream=duration,r_frame_rate $INPUT);
declare -r -i TBR=${streams_stream_0_r_frame_rate};
declare -r +i EXACT_DURATION=${format_duration};
declare -r -i DURATION=${format_duration%.*};
declare -r -i THUMBS_TO_GENERATE=$(divide $DURATION $TIMESPAN);

####################################################
# calculate generate data
####################################################
declare -r -i TIMESPAN_TBR=$(($TIMESPAN * $TBR));

declare -r +i SAMPLE_OUTPUT=$OUTPUT/sample.$IMG_EXT;
declare -r +i POSTER_OUTPUT=$OUTPUT/poster.$IMG_EXT;
declare -r +i VTT_OUTPUT=$OUTPUT/$VTT_NAME.$VTT_EXT;

declare +i IMG_OUTPUT;
declare +i IMG_SUFFIX;

####################################################
# update IMG_OUTPUT
####################################################
_update_img_output() { # $1 - sprites to geierate (number)
	local -r -i sprites=$1;
	IMG_SUFFIX="-%06d";
	if [[ $sprites -eq 1 ]]; then
		IMG_SUFFIX="";
	fi
	if [[ -z "${IMG_DIR}" ]]; then
		IMG_OUTPUT="$OUTPUT/${IMG_NAME}${IMG_SUFFIX}.$IMG_EXT"
	else
		IMG_DIR="${IMG_DIR%%/}/";
		IMG_OUTPUT="$OUTPUT/${IMG_DIR}${IMG_NAME}${IMG_SUFFIX}.$IMG_EXT";
	fi
}

# RUN
#
_update_img_output 0;

########################################################################################################
# PRINT
########################################################################################################

####################################################
# print options
####################################################
print_options() {
	echo "\n${YELLOW}-- options -----------------------------${RESET}\n";
	if [[ $MODE -eq $SPRITESHEET_MODE ]]; then echo "image sheets ${DGRAY}(-spritesheets)${RESET}"; fi
	if [[ $MODE -eq $THUMBNAILS_MODE ]]; then echo "separated images ${DGRAY}(-thumbnails)${RESET}"; fi
	echo "video file ${DGRAY}(-i)${RESET}: \t\t ${INPUT}";
	echo "video duration: \t\t ${DURATION} [${EXACT_DURATION}] ${DGRAY}(in seconds)${RESET}";
	echo "video tbr: \t\t\t ${TBR}";
	echo "file name ${DGRAY}(-n)${RESET}: \t\t ${FILE_NAME}";
	if [[ -z "${IMG_DIR}" ]]; then void; else echo "img dir ${DGRAY}(--img-dir)${RESET}: \t\t ${IMG_DIR}"; fi
	if [[ -z "${IMG_NAME}" ]]; then void; else echo "img name ${DGRAY}(--img-name)${RESET}: \t\t ${IMG_NAME}"; fi
	if [[ -z "${VTT_NAME}" ]]; then void; else echo "vtt name ${DGRAY}(--vtt-name)${RESET}: \t\t ${VTT_NAME}"; fi
	echo "thumb width ${DGRAY}(-w)${RESET}: \t\t ${WIDTH} ${DGRAY}(in pixels)${RESET}";
	echo "time span ${DGRAY}(-t)${RESET}: \t\t ${TIMESPAN} ${DGRAY}(in seconds)${RESET}";
	echo "time span tbr : \t\t ${TIMESPAN_TBR}";
	echo "thumbnails to generate: \t ${THUMBS_TO_GENERATE}";
	echo "sprite size: \t\t\t ${GENERATE_ROWS}x${GENERATE_COLUMNS}";
	# echo "output dir ${DGRAY}(-o)${RESET}: \t\t ${OUTPUT}";
	if [[ $MODE -eq $SPRITESHEET_MODE ]]; then echo "max grid size: \t\t\t ${GRID_SIZE}x${GRID_SIZE}"; fi
}

# RUN
#
print_options;

####################################################
# print generate data
####################################################
print_generate_data() {
	echo "\n${YELLOW}-- generate data -----------------------${RESET}\n";
	if [ $MODE -eq $SPRITESHEET_MODE ]; then
		local +i wasted_color=$RED;
		if [[ $SPRITES_THUMB_SPACE_WASTED -le 1 ]]; then wasted_color=$GREEN; fi
		echo "${YELLOW}sprite size:${RESET} ${GENERATE_ROWS}x${GENERATE_COLUMNS}";
		echo "${YELLOW}sprites to generate:${RESET} ${SPRITES_TO_GENERATE}";
		echo "${YELLOW}sprite space wasted:${wasted_color} ${SPRITES_THUMB_SPACE_WASTED}";
		echo "${YELLOW}IMG file pattern:${RESET} $(basename $IMG_OUTPUT $OUTPUT) x${SPRITES_TO_GENERATE}";
		unset wasted_color;
	elif [ $MODE -eq $THUMBNAILS_MODE ]; then
		echo "${YELLOW}IMG file pattern:${RESET} ${IMG_DIR}$(basename $IMG_OUTPUT) x${THUMBS_TO_GENERATE}";
	fi
	echo "${YELLOW}VTT file pattern:${RESET} $(basename $VTT_OUTPUT)";
	echo "${YELLOW}output directory:${RESET} ${OUTPUT}";
}

########################################################################################################
# FIND BEST GRID SIZE
########################################################################################################

if [[ $MODE -eq $SPRITESHEET_MODE ]]; then
	declare -r -i SCORE_MAX=$((GRID_SIZE * GRID_SIZE));
	declare -r -i SCORE_BASE=$((SCORE_MAX * SCORE_MAX));
	declare -r -i SCORE_BEST=$((SCORE_BASE / 10));
	declare -r -i SCORE_GOOD=$((SCORE_BEST / 10));
	declare -r -i SCORE_STEP=$((SCORE_GOOD / 10));
	declare +i -a GRID_DATA=();
	declare -a GRID_UNIQE_DATA=();
	# RUN
	#

	# print
	declare -r -i THUMBS_PER_SPRITE=$(( ($GENERATE_ROWS * $GENERATE_COLUMNS) ));
	declare -r -i SPRITES_TO_GENERATE=$(divide $THUMBS_TO_GENERATE $THUMBS_PER_SPRITE);
	declare -r -i SPRITES_THUMB_SPACE_AVAILABLE=$(( ($SPRITES_TO_GENERATE * $THUMBS_PER_SPRITE) ));
	declare -r -i SPRITES_THUMB_SPACE_WASTED=$(( ($SPRITES_THUMB_SPACE_AVAILABLE - $THUMBS_TO_GENERATE) ));
	# update
	_update_img_output $SPRITES_TO_GENERATE;
fi

########################################################################################################
# GENERATE
########################################################################################################

####################################################
# make output dir
####################################################
_make_output_dir() {
	if [[ ! -d $OUTPUT ]]; then mkdir -p $OUTPUT; fi
	if [[ -z "${IMG_DIR}" ]]; then echo; elif [[ ! -d $OUTPUT/$IMG_DIR ]]; then mkdir -p $OUTPUT/$IMG_DIR; fi
}
####################################################
# sample thumbnail size
####################################################
_sample_thumbnail_size() {
	ffmpeg -v $FFMPEG_LOG_LEVEL -i $INPUT -ss 00:00:00.0001 -y -an -sn -vsync 0 -q:v 5 -threads 1 -vf scale=$WIDTH:-1,select="not(mod(n\\,$TIMESPAN_TBR))" -frames:v 1 $SAMPLE_OUTPUT;
	_set_thumbnail_size_from_image $SAMPLE_OUTPUT;
	rm -f $SAMPLE_OUTPUT;
}
####################################################
# set thumbnail size from image
####################################################
_set_thumbnail_size_from_image() {
	eval $(ffprobe -v $FFMPEG_LOG_LEVEL -select_streams v:0 -of flat=s=_ -show_entries stream=width,height $1);
	WIDTH=${streams_stream_0_width};
	HEIGHT=${streams_stream_0_height};
}
####################################################
# create poster
####################################################
_create_poster() {
	#  dind random position
	local -r -i offset=$(divide $DURATION 100);
	local -r -i min=offset;
	local -r -i max=$(( DURATION - (offset * 2) ));
	while [[ "$position" -le $min ]]; do
		position=$RANDOM;
		let "position %= $max"; # Scales $position down within $MAX.
	done
	# create
	ffmpeg -v $FFMPEG_LOG_LEVEL -ss $position -i $INPUT -y -vframes 1 $POSTER_OUTPUT 2>&1;
}
####################################################
# create image sprite from video file
####################################################
_create_sprite() {
	ffmpeg -i $INPUT -y -hide_banner -v $FFMPEG_LOG_LEVEL -an -sn -vsync 0 -q:v 5 -threads 1 -vf scale=$WIDTH:-1,select="not(mod(n\\,$TIMESPAN_TBR))",tile=${GENERATE_ROWS}x${GENERATE_COLUMNS} $IMG_OUTPUT 2>&1;
}
####################################################
# create thumbnails from video file
####################################################
_create_thumbnails() {
	ffmpeg -i $INPUT -v $FFMPEG_LOG_LEVEL -hide_banner -y -an -sn -vsync 0 -q:v 5 -threads 1 -vf scale=$WIDTH:-1,select="not(mod(n\\,$TIMESPAN_TBR))" -copyts -f image2 -frame_pts true $IMG_OUTPUT 2>&1;
}
####################################################
# create VTT timestamp
####################################################
_create_vtt_timestamp() { # $1 - seconds to HH:MM:SS.000
	echo $(printf '%02d:%02d:%02d.000' "$(( $1 / 3600))" "$(( $1 / 60 % 60))" "$(( $1 % 60))");
}
####################################################
# create VTT file
####################################################
_create_vtt() {
	local -i row=0;
	local -i column=0;
	local -i sprite_num=1;
	local -i sprite_counter=1;
	local -i tbr_counter=0;
	local -i counter=0;
	local -i x=0;
	local -i y=0;
	local +i url;
	if [[ $MODE -eq $SPRITESHEET_MODE ]]; then
		_sample_thumbnail_size;
	fi
	# remove old file
	rm -f $VTT_OUTPUT;
	# get duration timestamp
	eval $(ffprobe -hide_banner -v $FFMPEG_LOG_LEVEL -sexagesimal -show_format -of flat=s=_ -read_intervals ${a}%+1 -select_streams v:0 -show_entries frame=pkt_pts_time $INPUT);
	local -r +i duration=${format_duration};
	local +i current="00:00:00.000";
	local +i timestamp=$(_create_vtt_timestamp $TIMESPAN);
	local -r -i last_count=$(( THUMBS_TO_GENERATE - 1 ));
	# write header
	printf "WEBVTT\n">>$VTT_OUTPUT;
	for ((a=TIMESPAN; a<=DURATION+TIMESPAN; a=a+TIMESPAN)); do
		tbr_counter=$((counter * TIMESPAN_TBR));
		if [[ $counter -lt $last_count ]]; then
			timestamp=$(_create_vtt_timestamp $a);
		else
			timestamp=$duration;
		fi
		# spritesheet
		if [[ $MODE -eq $SPRITESHEET_MODE ]]; then
			if [[ $sprite_counter -gt $THUMBS_PER_SPRITE ]]; then
				((sprite_counter=0))
				((sprite_num++))
			fi
			if [[ $row -ge $GENERATE_ROWS ]]; then
				((row=0));
				((column++));
				((x=0));
				((y=y+HEIGHT));
			else
				((row++))
			fi
		# thumbnails
		elif [[ $MODE -eq $THUMBNAILS_MODE ]]; then
			_set_thumbnail_size_from_image $(printf $IMG_OUTPUT "$tbr_counter");
		fi
		url="${IMG_DIR}${IMG_NAME}";
		# write time cue
		printf "\n%10s --> %10s" "$current" "$timestamp" >>$VTT_OUTPUT 2>&1;
		# write spritesheet url
		if [[ $MODE -eq $SPRITESHEET_MODE ]]; then
			if [[ $SPRITES_TO_GENERATE -eq 1 ]]; then
				printf "\n%s.%s#xywh=%d,%d,%d,%d\n" $url "$IMG_EXT" "$x" "$y" "$WIDTH" "$HEIGHT" >>$VTT_OUTPUT;
			else
				printf "\n%s$IMG_SUFFIX.%s#xywh=%d,%d,%d,%d\n" $url "$sprite_num" "$IMG_EXT" "$x" "$y" "$WIDTH" "$HEIGHT" >>$VTT_OUTPUT;
			fi
		# write thumbnails url
		elif [ $MODE -eq $THUMBNAILS_MODE ]; then
			if [[ -z "${WIDTH}" || -z "${HEIGHT}" ]]; then
				printf "\n%s$IMG_SUFFIX.%s\n" $url "$tbr_counter" "$IMG_EXT" >>$VTT_OUTPUT;
			else
				printf "\n%s$IMG_SUFFIX.%s#wh=%d,%d\n" $url "$tbr_counter" "$IMG_EXT" "$WIDTH" "$HEIGHT" >>$VTT_OUTPUT;
			fi
		fi
		current=$timestamp;
		((counter++))
		# spritesheet
		if [[ $MODE -eq $SPRITESHEET_MODE ]]; then
			((sprite_counter++))
			((x=x+WIDTH))
		fi
	done
}
####################################################
# generate
####################################################
_generate() {
	echo "${CYAN}------------------------${RESET}";
	local -i a=1;
	local -i t=3;
	if [[ $WITH_POSTER -eq 1 ]]; then t=t+1; fi

	# output dir
	echo "${DGRAY}[${a}/${t}]${RESET} make output dir";
	_make_output_dir;
	echo "${GREEN}created${RESET}\n";
	a=a+1;

	# WITH_POSTER
	if [[ $WITH_POSTER -eq 1 ]]; then

		echo "${DGRAY}[${a}/${t}]${RESET} make poster";
		_create_poster;
		echo "${GREEN}created${RESET}\n";
		a=a+1;

	fi

	# spritesheet
	if [[ $MODE -eq $SPRITESHEET_MODE ]]; then

		# generate
		echo "${DGRAY}[${a}/${t}]${RESET} create spritesheet x$SPRITES_TO_GENERATE";
		_create_sprite;
		echo "${GREEN}created files: ${SPRITES_TO_GENERATE}${RESET}\n";
		a=a+1;

	# thumbnails
	elif [[ $MODE -eq $THUMBNAILS_MODE ]]; then

		# generate
		echo "${DGRAY}[3/3]${RESET} create thumbnails x$THUMBS_TO_GENERATE";
		_create_thumbnails;
		echo "${GREEN}created files: ${THUMBS_TO_GENERATE}${RESET}\n";
		a=a+1;

	else
		echo "${RED}ERROR: invalid mode: ${MODE} ${RESET}" 1>&2;
		exit 0;
	fi

	# vtt
	echo "${DGRAY}[${a}/${t}]${RESET} create vtt file ";
	_create_vtt;
	echo "${GREEN}created VTT file${RESET}\n";
	a=a+1;

	echo "${CYAN}------------------------${RESET}";

	# print
	# echo "\n${CYAN}output directory:${RESET}\n${OUTPUT}";
	local -r +i vtt=($(ls -d $OUTPUT/$VTT_NAME*.$VTT_EXT));
	echo "\n${CYAN}(${#vtt[@]}) file(s) matched VTT file pattern:${RESET}\n${vtt[@]}";
	local +i images;
	if [[ -z "${IMG_DIR}" ]]; then
		images=($(ls -d $OUTPUT/$IMG_NAME*.$IMG_EXT));
	else
		images=($(ls -d $OUTPUT/$IMG_DIR/$IMG_NAME*.$IMG_EXT));
	fi
	echo "\n${CYAN}(${#images[@]}) file(s) matched image file pattern:${RESET}";
	for img in "${images[@]}";	do echo ${img}; done
	echo "${CYAN}------------------------${RESET}";
	echo "\n${GREEN}SUCCESS !${RESET}\n";
}

# RUN
#
print_generate_data;
_generate;
#
exit 0;
########################################################################################################
