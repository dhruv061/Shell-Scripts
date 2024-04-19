#This script move file from source to specfic folder based on it's file type like if it's PDF then it forwrded into the PDF folder.
#!/bin/bash

sourcepath=/home/ubuntu/Downloads/
destinationpath=/home/ubuntu/Task

for file in "$sourcepath"/*
do
    if [ -e "$file" ]
    then
        type="${file##*.}"
        filename="${file##*/}"
        filename="${filename%.*}"

        #cases
        case "$type" in
            jpg|jpeg|png|gif|bmp )
                Task="$destinationpath/images" ;;
            txt|odt )
                Task="$destinationpath/text" ;;
            pdf|doc|docx|xls|odp|ods )
                Task="$destinationpath/documents" ;;
            mp3|wav|flac|aac )
                Task="$destinationpath/music" ;;
            mp4|avi|mkv|mov )
                Task="$destinationpath/Movies" ;;
            zip|tar|gz|rar )
                Task="$destinationpath/compressed" ;;
            c|cpp|java|py|sh )
                Task="$destinationpath/programingFiles" ;;
            html|css|js|php )
                Task="$destinationpath/webreletd" ;;
            exe|out)
                Task="$destinationpath/Excutablefile" ;;
            * )
               Task="$destinationpath/others" ;;
        esac

        #make Task folder if not
        mkdir -p "$Task"

        #check if file already exists in the destination folder
        count=1
        while [ -e "$Task/$filename$count.$type" ]
        do
            ((count++))
        done

        #move files
        mv "$file" "$Task/$filename$count.$type"
        echo "Moved $file to $Task/$filename$count.$type"
    fi
done

echo "File Organization Complete"
