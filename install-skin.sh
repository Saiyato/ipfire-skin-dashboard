#! /bin/bash

# Locations of settings files
skindir="/srv/web/ipfire/html/themes/dashboard"

if [[ ! -d $skindir ]]; then mkdir -p $skindir; fi
if [[ ! -d $skindir/images ]]; then mkdir -p $skindir/images; fi
if [[ ! -d $skindir/include/css ]]; then mkdir -p $skindir/include/css; fi
if [[ ! -d $skindir/include/js ]]; then mkdir -p $skindir/include/js; fi
if [[ ! -d $skindir/include/webfonts ]]; then mkdir -p $skindir/include/webfonts; fi

# Download the manifest

wget "https://raw.githubusercontent.com/Saiyato/ipfire-skin-dashboard/master/MANIFEST"

# Download and move files to their destinations
echo Downloading files...

if [[ ! -r MANIFEST ]]; then
echo "Can't find MANIFEST file"
exit 1
fi

while read -r name path owner mode || [[ -n "$name" ]]; do
echo --
echo Download $name
echo $path
if [[ ! -d $path ]]; then mkdir -p $path; fi
if [[ $name != "." ]];
then
  wget "https://raw.githubusercontent.com/Saiyato/ipfire-skin-dashboard/master/$name" -O $path/$name
  chown $owner $path/$name
  chmod $mode $path/$name;
else
  chown $owner $path
  chmod $mode $path;
fi
done < "MANIFEST"

pakfire install perl-DBD-SQLite -y

# Tidy up

rm MANIFEST

# Update the skin to the dashboard
sed -i 's/THEME=.*/THEME=dashboard/g' /var/ipfire/main/settings

# Update language cache
update-lang-cache