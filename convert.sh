#/bin/bash

folder=$1
days=$2
# find $folder -mtime -1

echo `find "$folder" -mtime -$days -type f \( -name "*.mkv" -o -name "*.mp4" -not -name "*-mm.mp4" \)`
# exit 0
# find "$folder" -mtime -$days -type f \( -name "*.mkv" -o -name "*.mp4" \) |while read fname; do
find "$folder" -mtime -$days -type f \( -name "*.mkv" -o -name "*.mp4" -not -name "*-mm.mp4" \) |while read fname; do
# find "$folder" -mtime -$days -type f -name "*.mkv" |while read fname; do
  echo $fname
  # echo "${fname%.*}".srt
  file_json=`mediainfo --output=JSON "$fname"`

  # subs_stream=`ffprobe -v error -of json  "$fname" -of json -show_entries \"stream=index:stream_tags=language\" -select_streams s | jq '.streams[] | select(.tags.language == \"eng\")| .index'`
  # echo $subs_stream
  
  # check channels
  # TODO - get channel count first, look for English if > 1
  stereo_audio=`echo $file_json | jq '.[].track[] | select(."@type" == "Audio") | .Channels | contains("2")'`
  # echo stereo_audio=$stereo_audio

  subs_channel=`echo $file_json | jq '.[].track[] | select(."@type" == "Text") | select(.Title | contains("English")) | .ID|tonumber'`
  subs_channel=$(($subs_channel-1))
  # echo subs_channel=$subs_channel

  # -vcodec copy
  # -c:a aac
  # -vol 200 -af "pan=stereo|FL=0.8*FC+0.707*FL+0.707*BL+0.5*LFE|FR=0.8*FC+0.707*FR+0.707*BR+0.5*LFE" 
  # -map s:$subs_channel "${fname%.*}".srt
  
  ffmpeg_cmd="ffmpeg -hide_banner -v error -nostdin -y -i \"$fname\" -vcodec copy -c:a aac "

  # if [[ $VAR1 -ge $VAR2 ]] && [[ $VAR1 -ge $VAR3 ]]
  if [[ $stereo_audio != 'true' ]]
  then
    ffmpeg_cmd="$ffmpeg_cmd -vol 200 -af \"pan=stereo|FL=0.8*FC+0.707*FL+0.707*BL+0.5*LFE|FR=0.8*FC+0.707*FR+0.707*BR+0.5*LFE\" "
  fi

  # if [[ -n $subs_channel ]]
  # then
  #   ffmpeg_cmd="$ffmpeg_cmd -map \"0:s:m:language:eng\" \"${fname%.*}-mm.srt\""
  # fi

  ffmpeg_cmd="$ffmpeg_cmd \"${fname%.*}-mm.mp4\""
  echo $ffmpeg_cmd
  # echo rm \"$fname\"

  # do the deed!
  eval $ffmpeg_cmd
  ret_code=$?
  echo $ret_code
  # exit 0
  rm "$fname"
done
