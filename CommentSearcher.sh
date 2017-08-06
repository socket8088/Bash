#!/bin/bash
# Autor: Socket0x80
# Date: 25/7/2017

# Simple singlethread crawler that extracts html comments
StartPage=$1
ToCrawl="ToCrawl.list"
Crawled="Crawled.list"
Crawling="Crawling.list"
Crawling2="Crawling2.list"

# Crawl links
function CrawlLinks() {
UA="Mozilla/5.0 (X11; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0"

# Extract domain name
Domain_name=$(echo $1 | sed 's/http:..//' | sed 's/https:..//' | sed 's/www.//' | sed 's/\/.*$//')
clear
echo "
=============================================
[Socket0x80] - Crawler & HTML comment finder
=============================================
"
echo "[+] Main Domain: "$Domain_name
echo "[+] Fake User-Agent: Mozilla/5.0"

# Crawl start page
curl -s --user-agent "$UA" --url "$1" | grep -o "<a href=\".*.\"" | sed 's/<a href="//' | sed 's/\".*.$//' | sed 's/\"$//' | sed 's/\/$//' > $2

# Add start page to Crawled list
echo $1 > $3

# Add domain name to partial links
cat $2 | sed 's/^\//'$Domain_name'\//' > ToCrawl.tmp && mv ToCrawl.tmp $2

# Sort and Uniq on ToCrawl list
cat $2 | grep "$Domain_name" | sort | uniq > ToCrawl.tmp && mv ToCrawl.tmp $2

# Delete line of the start page of the ToCrawl list
cat $2 | grep -vx "$1" > ToCrawl.tmp && mv ToCrawl.tmp $2

# Copy ToCrawl.file to Crawling.file
cp $2 $4

CrawlExit=0
while [ $CrawlExit == 0 ]; do
	# LOOP
	while read line; do

		# Print Status
		Done=$(cat $3 | wc -l)
		ToDo=$(cat $2 | wc -l)
		echo "[+] Crawled: "$Done" Pending: "$ToDo

		# URL alredy crawled?
		if [ $(cat $3 | grep -x $line | wc -l) != 1 ]; then
			echo "[*] Currently crawling: "$line

			# Crawl URL
			curl -s --user-agent "$UA" --url "$line" | grep -o "<a href=\".*.\"" | sed 's/<a href="//' | sed 's/\".*.$//' | sed 's/\"$//' | sed 's/\/$//' | sed 's/^\//'$Domain_name'\//' | grep "$Domain_name" > $5

			# Add only new links to the list
			while read line2; do
				if [ $(cat $3 | grep -x "$line2" | wc -l) == 0 ]; then
					if [ $(cat $2 | grep -x "$line2" | wc -l) == 0 ]; then
						echo $line2 >> $2
					fi
				fi
			done < $5

			# Add it to Crawled.list
			echo $line >> $3

			# Sort and Uniq on Crawled list
			cat $3 | sort | uniq > Crawled.tmp && mv Crawled.tmp $3

			# Delete crawled line of the ToCrawl list
			if [ $(cat $2 | wc -l) != 1 ]; then
				cat $2 | grep -vx "$line" > ToCrawl.tmp && mv ToCrawl.tmp $2
			else
				# Delete last line
				cat /dev/null > $2
				CrawlExit=1
				echo "[+] Crawling ended."
			fi
		fi

	# Add delay if you want to simulate human navigation	
	#sleep 1

	done < $4

	# Copy ToCrawl.list to Crawling.list
	cp $2 $4

done 
}

function CommentSearch(){
while read line; do
	echo "[*] Extracting comments in URL: "$line
	curl -s "$line" | sed ':a;N;$!ba;s/\n//g' | egrep -o '(<\!--[^>]*-->|<\!--[^-]*-->)'
done < $1
}

CrawlLinks $StartPage $ToCrawl $Crawled $Crawling $Crawling2
CommentSearch $Crawled