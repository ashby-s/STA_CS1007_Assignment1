#!/bin/bash

#Adds a new record to log.txt indicating date and parameters where all logs are written into
echo -e "$(date) - $0 - ($1)\n" >> log.txt

#Checks if no more or less than 1 argument has been passed
#If so then returns an error statement and exits the script
if [ $# -ne 1 ]
then
  echo "Usage: $0 <dir>" >&2
  #If there was an error with the decleration of the script, writes this down
  echo -e "Insufficient Arguments provided\n" >> log.txt
  exit 1
fi

#Returns the top 5 largest files in the data directory
du -b $1/data/* | sort -gr | head -n5 | rev | cut -d '/' -f1 | rev
#Breaking down the last 3 commands:
# rev --> reverses the order of the text, so "blue" would become "eulb"
# cut -d '/' -f1 --> gets just the file name from this list, by using a delimeter of / and choosing the first string (this is done so it will always work regardless of file)
# rev --> reverses the order of the text to the correct format, so "eulb" would become "blue"

echo -e "\n" >> log.txt

#The use of the rev command was inspired by zedfoxus from https://stackoverflow.com/questions/22727107/how-to-find-the-last-field-using-cut
