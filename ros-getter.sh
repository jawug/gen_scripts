#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#/ Usage: ./ros-getter.sh
#/ Description: This script downloads the files used by Routerboard OS
#/ Examples: ./ros-getter.sh checks and then gets the latest release if it has not already been downloaded
#/ Examples: ./ros-getter.sh 6.42 checks and then gets the specified release if it has not already been downloaded
#/ Examples: ./ros-getter.sh --redownload checks and then gets the latest release
#/ Examples: ./ros-getter.sh --redownload 6.42 checks and then gets the specified release
#/ Examples: ./ros-getter.sh --tag="current" This creates/updates the tagname specified
#/ Options: None
#/   --help: Display this help message
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

FILE=$(basename "$0")
fn="${FILE%%.*}"
#readonly LOG_FILE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/$(basename "$0").log"
readonly LOG_FILE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/$fn.log"
info()    { echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO]    $*" | tee -a "$LOG_FILE" >&2 ; }
warning() { echo "$(date "+%Y-%m-%d %H:%M:%S") [WARNING] $*" | tee -a "$LOG_FILE" >&2 ; }
debug()   { echo "$(date "+%Y-%m-%d %H:%M:%S") [DEBUG]   $*" | tee -a "$LOG_FILE" >&2 ; }
error()   { echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR]   $*" | tee -a "$LOG_FILE" >&2 ; }
fatal()   { echo "$(date "+%Y-%m-%d %H:%M:%S") [FATAL]   $*" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }

cleanup() {
    info "Cleaning up"
    cd "$cpwd"
    info "Done!"
}

# System Variables
rosSaveDirectory="/data/routeros/"
rosHTTPBaseURL="https://download2.mikrotik.com/routeros"
rosHTTPBaseURL2="https://download.mikrotik.com/routeros"
wgetExtraParam=""

# Internal Variables
cpwd=$(pwd)
redownload=""
isdownloaded=""
version=""
isTagged=false
## The ROS platforms
declare -a rosArray=("mipsbe" "smips" "tile" "powerpc" "arm" "x86" "mmips" )
## The all packages platforms
declare -a rosPackArray=("mipsbe" "smips" "tile" "ppc" "arm" "x86" "mmips" )
## The Dude platforms
declare -a rosDudeArray=("-tile" "-arm" "-mmips" "")
## The CHR platforms
declare -a chrArray=("vmdk" "vhdx" "vdi" "img.zip")
## Required directories
declare -a dirArray=("routeros" "general" "all_packages" "dude" "chr" )

info "Starting..."

getLatestVersion() {
    version=$(wget $wgetExtraParam $rosHTTPBaseURL/LATEST.6 -q -O - | awk '{print $1}')
    info "The latest release is $version"
}

determineVersion(){
    info "Determing which version to get"
    re='^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}'
    rc='^[0-9]{1,2}\.[0-9]{1,2}rc[0-9]{1,2}'
    beta='^[0-9]{1,2}\.[0-9]{1,2}beta[0-9]{1,2}'
    if [[ $1 =~ $re ]] ; then
        version="$1"
        elif [[ $1 =~ $rc ]] ; then
        version="$1"
        elif [[ $1 =~ $beta ]] ; then
        version="$1"
    else
        warning "No valid version specified. Checking for the latest release"
        getLatestVersion
    fi
    info "Release $version has been selected to be downloaded"
}

info "Checking for parameters..."
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -r|--redownload) # Redownload option
            redownload="yes"
            shift # past value
        ;;
        --tag=*) # Show the node's firmware
            tagName="${key#*=}"
            isTagged=true
            shift # past value
        ;;
        *)    # release
            determineVersion "$1"
            shift
        ;;
    esac
done

createDirectory(){
    if [ -d "$1" ]; then
        debug "Directory \"$1\" already exists, skipping mkdir for it"
    else
        mkdir "$1"
    fi
}

createRequiredDirectories() {
    info "Creating required directories for $version..."
    createDirectory "$version"
    cd "$version" || exit
    for i in "${dirArray[@]}"
    do
        createDirectory "$i"
    done
}

checkReleaseExists() {
    if [ -d "$version" ]; then
        isdownloaded="yes"
    fi
}

downloadFile() {
    info "Downloading $2..."
    startDownload=$(date +%s)
    wget -q --progress=bar $wgetExtraParam "$1" -O "$2" || exit
    endDownload=$(date +%s)
    filesize=$(wc -c "$2" | awk '{print $1}')
    downloadTime=$(( endDownload - startDownload ))
    info "Finished downloading $2, size: $filesize bytes, time: $downloadTime second(s)"
}

getRouterOSFiles(){
    cd routeros || exit
    info "Getting basic upgrade package(s)..."
    for i in "${rosArray[@]}"
    do
        downloadFile "$rosHTTPBaseURL/$version/routeros-$i-$version.npk" "routeros-$i-$version.npk"
    done
    #cd - > /dev/null || exit
    cd - 2>&1 >/dev/null || exit
}

getGeneralFiles(){
    cd general || exit
    info "Getting general files..."
    downloadFile "$rosHTTPBaseURL/$version/mikrotik-$version.iso" "mikrotik-$version.iso"
    downloadFile "$rosHTTPBaseURL/$version/dude-install-$version.exe" "dude-install-$version.exe"
    downloadFile "$rosHTTPBaseURL/$version/netinstall-$version.zip" "netinstall-$version.zip"
    cd - 2>&1 >/dev/null || exit
}

getAllPackagesFiles(){
    cd all_packages || exit
    info "Getting all package(s)..."
    for i in "${rosPackArray[@]}"
    do
        downloadFile "$rosHTTPBaseURL/$version/all_packages-$i-$version.zip" "all_packages-$i-$version.zip"
    done
    cd - 2>&1 >/dev/null || exit
}

getDudeFiles(){
    cd dude || exit
    info "Getting The Dude file(s)..."
    for i in "${rosDudeArray[@]}"
    do
        downloadFile "$rosHTTPBaseURL2/$version/dude-$version$i.npk" "dude-$version$i.npk"
    done
    cd - 2>&1 >/dev/null || exit
}

getCHRFiles(){
    cd chr || exit
    info "Getting Cloud Hosted Router files..."
    for i in "${chrArray[@]}"
    do
        downloadFile "$rosHTTPBaseURL/$version/chr-$version.$i" "chr-$version.$i"
    done
    cd - 2>&1 >/dev/null || exit
}

checkTargetDirectory(){
    if [ ! -d "$rosSaveDirectory" ]; then
        error "Save directory \"$rosSaveDirectory\" does not exist"
        exit 1
    fi
}

appendTag(){
    if [ $isTagged ]; then
        info "Updating tag \"$tagName\" with $version"
        fn="$rosSaveDirectory$tagName.release"
        echo "$version" > "$fn"
    fi
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    trap cleanup EXIT
    checkTargetDirectory
    if [ -z "$version" ]; then
        determineVersion ""
    fi
    
    cd "$rosSaveDirectory" || exit 1
    
    #    if [ ! -z "$redownload" ]
    if [ -n "$redownload" ]
    then
        createRequiredDirectories
        getRouterOSFiles
        getAllPackagesFiles
        getDudeFiles
        getCHRFiles
        getGeneralFiles
    else
        checkReleaseExists
        #        if [ ! -z "$isdownloaded" ]
        if [ -n "$isdownloaded" ]
        then
            info "Release $version has been downloaded previously, skipping download"
        else
            info "Download files..."
            createRequiredDirectories
            getRouterOSFiles
            getAllPackagesFiles
            getDudeFiles
            getCHRFiles
            getGeneralFiles
        fi
    fi
    appendTag
fi
