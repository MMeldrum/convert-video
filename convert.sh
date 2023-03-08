#/bin/bash

# folder=$1
# days=$2
# limit=$3

folder=${folder:-.}
days=${days:-7}
limit=${limit:-99999}

while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        # echo $1 $2 // Optional to see the parameter:value result
   fi
  shift
done

echo Scanning $folder
echo Files from the last $days days
echo Process $limit files only

# convert mkv to mp4 first
echo find "$folder" -mtime -$days -type f \( -name "*.mkv" \) \| head -n $limit
find "$folder" -mtime -$days -type f \( -name "*.mkv" \) | head -n $limit |while read fname; do
  echo converting $fname from mkv to mp4
  ffmpeg_cmd="ffmpeg -hide_banner -v error -nostdin -y -i \"$fname\" -vcodec copy -acodec copy \"${fname%.*}.mp4\""
  eval $ffmpeg_cmd
  # delete original *gulp*
  rm "$fname"
done

echo find "$folder" -mtime -$days -type f \( -name "*.mp4" -not -name "*-2ch.mp4" \) \| head -n $limit
find "$folder" -mtime -$days -type f \( -name "*.mp4" -not -name "*-2ch.mp4" \) | head -n $limit |while read fname; do
  echo converting $fname codecs
  file_json=`mediainfo --output=JSON "$fname"`

  # check channels
  stereo_audio=`echo $file_json | jq '.[].track[] | select(."@type" == "Audio") | .Channels | contains("2")'`
  echo stereo_audio: $stereo_audio

  # check for subtitles
  subs_channel=`echo $file_json | jq '.[].track[] | select(."@type" == "Text") | select(.Title | contains("English")) | .ID|tonumber'`
  if [ -n "$var" ]; then
    subs_channel=$(($subs_channel-1))
  fi

  # base ffmpeg command
  ffmpeg_cmd="ffmpeg -hide_banner -v error -nostdin -y -i \"$fname\" -vcodec copy -c:a aac "

  # if not stereo, convert to stereo
  if [[ $stereo_audio != 'true' ]]
  then
    echo 'converting audio to stereo for' $fname
    ffmpeg_cmd="$ffmpeg_cmd -vol 200 -af \"pan=stereo|FL=0.8*FC+0.707*FL+0.707*BL+0.5*LFE|FR=0.8*FC+0.707*FR+0.707*BR+0.5*LFE\" "
  fi

  # TODO if found, extract subtitles
  # if [[ -n $subs_channel ]]
  # then
  #   ffmpeg_cmd="$ffmpeg_cmd -map \"0:s:m:language:eng\" \"${fname%.*}-tmp.srt\""
  # fi

    # if conversion required then do the deed!
  if [[ $stereo_audio != 'true' ]]; then
    
    ffmpeg_cmd="$ffmpeg_cmd \"${fname%.*}-tmp
    .mp4\""
    echo $ffmpeg_cmd

    eval $ffmpeg_cmd

    ret_code=$?
    echo $ret_code

    # delete original *gulp*
    echo rm \"$fname\"
    rm "$fname"

    renamepath=$(dirname "$fname")
    # echo renamepath $renamepath
    # echo \"renamepath\" \"$renamepath\"/*.mp4
    # ls "$renamepath"/*.mp4

    # echo \"${fname%.*}-tmp.mp4\"
    rename -v 's/-tmp/-2ch/' "${fname%.*}-tmp.mp4"
  else
    echo Skipping conversion - already stereo audio
    echo renaming \"$fname\"
    rename -v 's/-tmp//' "$fname"
    rename -v 's/.mp4/-2ch.mp4/' "$fname"
  fi
done

# <Location id="1" path="/media/plex/Films"/>
# <Location id="2" path="/media/plex/Kids Films"/>
# <Location id="3" path="/media/plex/TV"/>
# <Location id="4" path="/media/plex/Kids TV"/>

# Refresh Plex Library - Partial Scan 
echo Scanning Plex folder $folder
echo curl http://192.168.1.35:32400/library/sections/3/refresh?X-Plex-Token=1d-zW73bAR1cSzEdpF9D
curl http://192.168.1.35:32400/library/sections/3/refresh?X-Plex-Token=1d-zW73bAR1cSzEdpF9D
