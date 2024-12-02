#!/bin/bash
# script to reencode .ts files to .mkv and saves it in a new location, then removes commercials and saves a new new file with the same name as the processed .mkv 
# version 1.0, 2024-12-02
# usage: reencode.sh filename.ts

# variables
logfile=/var/log/jellyfin_reencode.log
processed_shows=/tv_processed


path="$1" # full filepath and filename
fn=$(basename "$path") # filename only
viddir=$(dirname "$path") # path without filename
season=$(basename "$viddir") # season name of path
showdir=$(dirname "$viddir") # path without season
show=$(basename "$showdir") # show name
outdir="$processed_shows/$show" 

mkdir -p "$outdir" # make directory

# reencode video
echo "ffmpeg encoding $path..." >> $logfile

if [[ -f "$processed_shows/$show/$season/$fn.mkv" ]]; then
    echo "File $processed_shows/$show/$season/$fn.mkv exists!" >> $logfile
else
    echo "File does not already exist. Will process with ffmpeg..."
    # ffmpeg process creates a new mkv container with compatible streams (audio, video, etc) 
    /usr/lib/jellyfin-ffmpeg/ffmpeg -fflags +genpts+igndts -y -i "$path" -codec copy -max_muxing_queue_size 2048 -avoid_negative_ts auto -max_interleave_delta 0 "$outdir/$fn.mkv"

    rc=$? # checks if the previous command was successful
    if [ $rc = 0 ] ; then
        echo "ffmpeg was successful. Moving file...." >> $logfile
        mkdir -p "$processed_shows/$show/$season" #-- save the TS recording
        mv "$outdir/$fn.mkv" "$processed_shows/$show/$season/"
        echo "Comcut processing..." >> $logfile
        /config/comcut "$processed_shows/$show/$season/$fn.mkv" # checks for commercials, builds a new file with no commercials and saves it as the same filename
    else
        echo "Error encoding...." >> $logfile
    fi
fi

echo "Done encoding $path" >> $logfile
