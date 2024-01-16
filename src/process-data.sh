#!/bin/sh

set -u

#Checks if there is a -t flag, and creates a text file with all the required files to check (depending on flag)
#Code below inspired by Gilles Quénot from https://stackoverflow.com/questions/14447406/bash-shell-script-check-for-a-flag-and-grab-its-value
while getopts ":t:" opt;do
	Directory=$2

	#Adds a new record to log.txt indicating date and parameters where all logs are written into
	echo -e "$(date) - $0 - ($1, $2)\n" >> log.txt

	#Checks if directory exits, if not halts script
        if [ ! -e $Directory ]; then
        	echo "Invalid Input. Directory $Directory does not exist." >&2

			echo -e "Directory $Directory does not exist.\n" >> log.txt
			echo -e "\n" >> log.txt

        	exit 1
        fi

	if [ $opt = 't' ]; then
		#Only uses the top 5 largest files
		./filter.sh $Directory > filestocheck.txt
		echo -e "-t flag used.\n" >> log.txt
	else
		#Uses all possible files in the data directory
		basename -a $Directory/data/* > filestocheck.txt
		echo -e "-t flag NOT used.\n" >> log.txt
	fi
done

# If there was no flags (so only 1 argument) then sets directory variable, and creates a text file with all the required files to check
if [ $# -eq 1 ]; then
	Directory=$1

	#Adds a new record to log.txt indicating date and parameters where all logs are written into
	echo -e "$(date) - $0 - ($1)\n" >> log.txt

	#Checks if directory exits, if not halts script
	if [ ! -e $Directory ]; then
        	echo "Invalid Input. Directory $Directory does not exist." >&2

			echo -e "Directory $Directory does not exist.\n" >> log.txt
			echo -e "\n" >> log.txt

        	exit 1
	fi

	#Uses all possible files in the data directory
	basename -a $Directory/data/* > filestocheck.txt
	echo -e "-t flag NOT used.\n" >> log.txt
fi

#Creates(or updates) with headers for the necessary data to be output to
echo "route,duration" > $Directory/out/duration.csv
echo "id,fuel" > $Directory/out/engine.csv

#Initialising TotalTime for gathering all possible timings
TotalTime=0

#Creates a Dictionary for VehicleId
declare -A VehicleIdDict

#Goes through all of the files required to be accessed from filestocheck.txt (determined through flag)
while read FileName; do

	RouteName=$(sed 's/.csv//' <<< $FileName)

	echo "Checking $RouteName route." >> log.txt

	#Determines the amount of rows and columns used in the csv file
	#Code below provided by Erik and inspired by GGibson from https://stackoverflow.com/questions/5761212/how-do-i-count-the-number-of-rows-and-columns-in-a-file-using-bash
	NumOfRows=$(wc -l < "$Directory/data/$FileName")
	NumOfCol=$(head -n1 "$Directory/data/$FileName" | grep -o "\",\"" | wc -l) ; NumOfCol=$((NumOfCol + 1))

	#Goes through all the rows of the csv file
	for Row in $(seq 2 $NumOfRows); do

		#Determines the time between the start and end of the journey (giving length of journey), and adds all of these together.
		StartTime=$(tail -n+$Row "$Directory/data/$FileName" | head -n1 | cut -d ',' -f1)
		FinalTime=$(tail -n+$Row "$Directory/data/$FileName" | head -n1 | cut -d ',' -f$NumOfCol)
		TotalTime=$(($TotalTime + $(($FinalTime - $StartTime))))

		#Gathers the name of the vehicle in this row, and checks if a file for that VehicleId exists
		VehicleId=$(tail -n+$Row "$Directory/data/$FileName" | head -n1 | cut -d ',' -f$((NumOfCol+1)))

		#Gathers the amount of fuel used by the vehicle in the current row (so journey)
		NewFuelVal=$(tail -n+$Row "$Directory/data/$FileName" | head -n1 | cut -d ',' -f$((NumOfCol+2)))

		#Code below inspired by Dan Nanni from https://www.xmodulo.com/key-value-dictionary-bash.html
		#Checks if Key for current VehicleId already exists
		if [ -v "VehicleIdDict[$VehicleId]" ]; then
			#If it exists, adds the new amount of fuel to the value already saved in dictionary, and saves as value
			VehicleIdDict[$VehicleId]=$(($NewFuelVal + VehicleIdDict[$VehicleId]))
		else
			#If it does not exists, creates a new key with the value pair being the new amount of fuel
			VehicleIdDict[$VehicleId]=$NewFuelVal
			echo "Added $VehicleId to Dictionary." >> log.txt
		fi

	done

	#Finds the average of the time using the number of rows. Converts this average into the correct format of Hours, Minutes and Seconds
	#Code below provided by ACyclic from https://stackoverflow.com/questions/12199631/convert-seconds-to-hours-minutes-seconds
	AverageTime=$(date -d@$((TotalTime / $((NumOfRows - 1)))) -u +%H:%M:%S)

	#Appends this data to the correct csv as required, using correct format
	echo "$RouteName,$AverageTime" >> $Directory/out/duration.csv

	#Resets total  minutes for next file
	TotalTime=0

done < filestocheck.txt

#Checks through the Dictionary VehicleIdDict, and appends the vehicleId and fuel data to the Midengine.txt using correct syntax(though wrong order)
#Code below inspired by Dan Nanni from https://www.xmodulo.com/key-value-dictionary-bash.html
for Key in "${!VehicleIdDict[@]}" ; do
	echo "$Key,${VehicleIdDict[$Key]}" >> $Directory/out/Midengine.txt
done

#Sorts the Midengine.txt and appends this to engine.csv (in correct order)
sort "$Directory/out/Midengine.txt" >> "$Directory/out/engine.csv"

#Removes unncesary files and directories that are not needed in the output
rm filestocheck.txt
rm $Directory/out/Midengine.txt

echo -e "\n" >> log.txt