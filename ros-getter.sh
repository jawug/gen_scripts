#!/bin/bash
ros_dir="/data/routeros"
http_base_url="http://download2.mikrotik.com/routeros"
START=$(date +%s)
cd $ros_dir || exit
if [ -z "$1" ]
    then
        echo "Getting the latest release"
        version=$(wget $http_base_url/LATEST.6 -q -O - | awk '{print $1}')
else
    echo "Release parameter has been supplied. Using that in order to download specific ROS release"
    version=$1
fi

if [ ! -d "$version" ]; then
    echo "Release $version has not been downloaded as yet."
    echo "Creating directories for $version..."
    mkdir "$version"
    cd "$version" || exit
    mkdir routeros
    mkdir netinstall
    mkdir all_packages
    mkdir capsman
    mkdir chr
    #RouterOS main - Start
    cd routeros || exit
    echo "Getting basic upgrade package(s)..."
    for i in "mipsbe" "smips" "arm" "x86" "powerpc" "mipsle" "tile"
        do
        #RouterOS packages
        echo "-> $i"
        wget -q --progress=bar "$http_base_url/$version/routeros-$i-$version.npk"
    done
    cd - || exit
    #RouterOS main - End
    #RouterOS netinstall - Start
    cd netinstall || exit
    echo "Getting netinstall..."
    for i in "mipsbe" "smips" "arm" "x86" "powerpc" "mipsle" "tile"
        do
        #RouterOS netinstall
        echo "-> $i"
        wget -q --progress=bar "$http_base_url/$version/netinstall-$version-$i.zip"
    done
    cd - || exit
    #RouterOS netinstall - End
    #All packages - Start
    cd all_packages || exit
    echo "Getting all package(s)..."
    for i in "mipsbe" "smips" "arm" "x86" "powerpc" "mipsle" "tile"
        do
        echo "-> $i"
        wget -q --progress=bar "$http_base_url/$version/all_packages-$i-$version.zip"
    done
    cd - || exit
    #All packages - End
    #CAPsMAN - Start
    cd capsman || exit
    echo "Getting CAPsMAN package(s)..."
    for i in "-mipsbe" "-smips" "-arm" "-x86" "-powerpc" "-mipsle" "-tile"
        do
        echo "-> $i"
        wget -q --progress=bar "$http_base_url/$version/wireless-cm2-$version$i.npk"
    done
    cd - || exit
    #CAPsMAN - End
    #All Cloud Hosted Router - Start
    cd chr || exit
    echo "Getting Cloud Hosted Router images..."
    for i in "vmdk" "vhdx" "vdi" "img.zip"
        do
        echo "-> $i"
        wget -q --progress=bar "$http_base_url/$version/chr-$version.$i"
    done
    cd "$ros_dir" || exit
    #All Cloud Hosted Router - End
    echo "Finished downloading files for release $version"
else
    echo "Release $version has already been downloaded"
fi
END=$(date +%s)
DIFF=$(( END - START ))
echo "Execution time: $DIFF second(s)"
