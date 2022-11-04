#/bin/bash

folder=$1
days=$2

echo `find "$folder" -mtime -$days -type f \( -name "*.mkv" -o -name "*.mp4" -not -name "*-mm.mp4" \)`
find "$folder" -mtime -$days -type f \( -name "*.mkv" -o -name "*.mp4" -not -name "*-mm.mp4" \) |while read fname; do
  echo $fname
  file_json=`mediainfo --output=JSON "$fname"`

  # check channels
  stereo_audio=`echo $file_json | jq '.[].track[] | select(."@type" == "Audio") | .Channels | contains("2")'`

  # check for subtitles
  subs_channel=`echo $file_json | jq '.[].track[] | select(."@type" == "Text") | select(.Title | contains("English")) | .ID|tonumber'`
  subs_channel=$(($subs_channel-1))

  # base ffmpeg command  
  ffmpeg_cmd="ffmpeg -hide_banner -v error -nostdin -y -i \"$fname\" -vcodec copy -c:a aac "

  # if not stereo, convert to stereo
  if [[ $stereo_audio != 'true' ]]
  then
    ffmpeg_cmd="$ffmpeg_cmd -vol 200 -af \"pan=stereo|FL=0.8*FC+0.707*FL+0.707*BL+0.5*LFE|FR=0.8*FC+0.707*FR+0.707*BR+0.5*LFE\" "
  fi

  # TODO if found, extract subtitles
  # if [[ -n $subs_channel ]]
  # then
  #   ffmpeg_cmd="$ffmpeg_cmd -map \"0:s:m:language:eng\" \"${fname%.*}-mm.srt\""
  # fi

  ffmpeg_cmd="$ffmpeg_cmd \"${fname%.*}-mm.mp4\""
  echo $ffmpeg_cmd

  # do the deed!
  eval $ffmpeg_cmd

  ret_code=$?
  echo $ret_code

  # delete original *gulp*
  rm "$fname"
done
