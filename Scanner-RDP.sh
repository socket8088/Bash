#!/bin/bash
# Autor: Xavi Beltran
# Date: 28/05/2017

# RDP Service on port 3389 OS Detection
# This script uses xfreerdp, a opensource RDP client
# Also it uses 2 OCRs:
#	- tesseract
#	- gocr

# Init
clear
cat /dev/null > results.txt

# Parameter control
if [ $# != 1 ]
	then
	echo "[-] Usage:
	sh RDP-Scanner.sh input-file.txt
	"
	exit
fi

# Save input file name to local variable
list=$1

# Read file line by line
while read IP
	do
	echo "[*] Trying to connect with: "$IP

	# Try RDP connection
	# Change stdin, we can't use same stdin as the main program, because it gets out of this while
	# We look por the word "user", if it finds it returns a 1 to the stdout, that we changed to flag file
	# Also i redirect stderr to garbage file
	cat /dev/null > flag
	cat /dev/null > dns
	xfreerdp $IP < /dev/null 2> garbage | grep -i user | wc -l > flag &

	# Let's check flag file
	# If flag value it is not 1, it means that server started a new connection
	sleep 20
	if [ $(cat flag | grep 1 | wc -l) != 1 ] && [ $(ps -ef | grep xfreerdp | grep -v grep | wc -l) == 1 ]
		then
		echo "[*] Starting RDP connection"
	
		# Save rdp process PID
		PID=$(ps -ef | grep xfreerdp | grep -v grep | awk '$3~/'$$'/{print$2}')
		echo "[*] Extracting RDP process PID: "$PID

		# Make a screenshot
		echo "[*] Saving screenshot: "$IP".jpg"
		# -c for countdown
		scrot -b -d5 -q100 $IP.jpg

		# Kill process
		echo "[*] Sending kill signal to RDP process: "$PID
		kill $PID

		# OCR image to text
		echo "[*] Extracting text from image file using OCR"
		# OCR tesseract for Windows 2003
		tesseract $IP.jpg output 2> garbage
		# OCR gocr for Windows XP
		gocr $IP.jpg -e garbage -o output2.txt

		# Extract DNS from IP
		curl ipinfo.io/$IP 2> garbage >> dns
		#hostname=$(cat dns | grep "hostname.:" | sed 's/^.*.:..//' | sed 's/..$//')
		organitzation=$(cat dns | grep "org.:" | sed 's/^.*.:..//' | sed 's/..$//')
		echo "[-] Organitzation name: "$organitzation

		# Find OS using OCR result
		if [ $(cat output.txt | grep -i "Winduws" | wc -l) == 1 ]
			then
				echo "[-] OS detection complete: Windows XP"
				echo $IP";Windows XP;"$organitzation >> results.txt
		elif [ $(cat output2.txt | grep -i "w.ndow5" | wc -l) == 1 ]
			then
				echo "[-] OS detection complete: Windows Server 2003"
				echo $IP";Windows 2003;"$organitzation >> results.txt
		else
				echo "[-] Unknown OS: Windows 2000/ Linux RDP client / Others"
				echo $IP";Unknown;"$organitzation >> results.txt
		fi

	else
		
		if [ $(cat flag | grep 1 | wc -l) == 1 ]
			then
			echo "[-] Server ask for user in SSH connection"
			echo $IP";SSH credentials" >> results.txt
		else
			echo "[-] No response from Server. Timeout"
			echo $IP";Timeout" >> results.txt
		fi

	fi

echo "--------------------------------------------------------------------------------"

done < $list


