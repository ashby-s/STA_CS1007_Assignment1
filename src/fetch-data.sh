#!/bin/sh

#Adds a new record to log.txt indicating date and parameters where all logs are written into
echo -e "$(date) - $0 - ($1, $2)\n" >> log.txt

#Checks if no more or less than 2 argument has been passed
#If so then returns an error statement and exits the script
if [ $# -ne 2 ]
then
  echo "Usage: $0 <dir> <url>" >&2
  echo -e "Insufficient Arguments provided\n" >> log.txt
  exit 1
fi

DirName=$1
BaseURL=$2

#If directory does not exist, creates directory
if [ ! -e $DirName ]; then
	mkdir $DirName
	echo -e "Created new directory: $DirName \n" >> log.txt
fi

cd $DirName

#Deletes contents of data directory if it exists, otherwise creates this directory
if [ -e data/ ]; then
	rm -rf data/*
else
	mkdir data
	echo -e "Created new directory: data\n" >> ../log.txt
fi

#Deletes contents of out directory if it exists, otherwise creates this directory
if [ -e out/ ]; then
        rm -rf out/*
else
    	mkdir out
	echo -e "Created new directory: out\n" >> ../log.txt
fi

#Downloads the required textfile from the webpage that was input (as an argument)
wget $BaseURL"filelist.txt"

#Iterates through the filelist.txt file, and downloads the list of files in the data directory
#Command inspired by Bruno De Fraine from https://stackoverflow.com/questions/1521462/looping-through-the-content-of-a-file-in-bash
while read Line; do
	#Replaces all space characters with %20
	NEWURL=`echo $BaseURL$Line | sed s/\ /%20/`
	echo "Downloading to data from\: $NEWURL" >> ../log.txt
	wget -P data/ $NEWURL
done < filelist.txt

echo -e "\n" >> ../log.txt

#Deletes filelist.txt after its use
rm filelist.txt

cd ..
