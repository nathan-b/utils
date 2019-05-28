#/bin/sh

while [ "$#" -gt "0" ]; do
	if [ ! -z "$1" ]; then
		dpkg -s $1 > /dev/null 2>&1
		if [ "$?" -eq "0" ]; then
			echo $1
		fi
	fi
	shift
done

