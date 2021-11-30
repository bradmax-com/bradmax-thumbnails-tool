# bradmax thumbnails tool

<br/>
Shell script to generate thumbnail images from video file with vtt file as thumbnails descriptor. 
Require [ffmpeg][ffmpeg] and [ffprobe][ffprobe] to be installed.
<br/>
<br/>

There are two wasy to generate thumbnails for video file:
- as __spritesheets__. Images are merged into sprites sheets (flag *-spritesheets* ). These is default behaviour.
- as __thumbnails__. Each thumbnail as separated image file (flag *-thumbnails* ).
<br/>

### Options:
- *required*<br/>
*```--input (-i)```* - [string] path to ffmpeg input video file.<br/>
*```--output (-o)```* - [string] path to output directory.

- *optional*<br/>
*```-spritesheets```* - when flag is added will generate image sprite files with thumbnails (default).<br/>
*```-thumbnails```* - when flag is added will generate single image for each thumbnail.<br/>
*```-poster```* - when flag is added will also generate poster image with random frame from input video.<br/>
*```--timespan (-t)```* - [integer] time span (in seconds) between each thumbnail, default 10 sec. It will generate thumbnail every 10 seconds.<br/>
*```--width (-w)```* - [integer] width (in pixels) of each thumbnail, default 160 px.<br/>
*```--name (-n)```* - [string] base name for generated files, default 'spritesheet' when *-spritesheets* or 'thumbnail' when *-thumbnails* flag is enabled.<br/>
*```--vtt-name```* - [string] override base name (-n) for VTT file. When provided generated vtt file path will be "[*--output*]/[*--vtt-name*].vtt".<br/>
*```--img-name```* - [string] override base name (-n) for image files. When provided generated images path will be "[*--output*]/[*--img-name*].jpg".<br/>
*```--img-dir```* - [string] base dir for image files. When provided generated images path will be "[*--output*]/[*--img-dir*]/[*--(img-)name*].jpg".<br/>
*```--help (-h)```* - display help message.

### Note:
When flag *-spritesheets* is enabled script will probe video file to find best match for image grid dimmentions based on provided video file duration and *--timespan* option value. 
Then You will need to choose one of proposed grid sizes.
Best grid sizes are ones that do not have unused thumbnail spaces. For example if video duration is 30 seconds, thumbnails *-timespan* set to 10 (seconds) and choosed grid size is 2x2, then 1 thumbnail space will be unused, because (30s / 10s) = 3, but 2x2 = 4,
<br/>

### Usage:
```
$ thumbnails.sh -spritesheets -poster -i /input/video.mp4 -o /output/directory -w 160 -t 10 --vtt-name thumbnails --img-dir images/directory --img-name image-file-name
```
<br/>

---

[ffmpeg]: https://www.ffmpeg.org/
[ffprobe]: https://ffmpeg.org/ffprobe.html
