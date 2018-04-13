# ros-getter


<!--- [![Build Status](https://travis-ci.org/jawug/ros-getter.png?branch=master)](https://travis-ci.org/jawug/ros-getter) -->

## Overview
This script is used to download the files for Mikrotik RouterOS releases. When running the script you can either specify a specific release or else the script will try to get the latest "Current" release.

## Getting started
The __rosSaveDirectory__ variable in the script should be changed to use the save path for where you want to the files to be stored.

**NOTE** If the path for "rosSaveDirectory" does not exist the script will fail and provide a message in the log file indicating as such.

__wgetExtraParam__ is currently blank however you can add additional settings for wget such as proxy settings

## Getting help  
  ```shell
  ./ros-getter.sh --help
  ```

## Using
* Download the latest "current" release:
  ```shell
  ./ros-getter.sh
  ```
* Re-download the latest "current" release:
  ```shell
  ./ros-getter.sh --redownload
  ```
  *or*
  ```shell
  ./ros-getter.sh -r
  ```
* Downloading a specific release:
  ```shell
  ./ros-getter.sh 6.40.7
  ```
  *or*
  ```shell
  ./ros-getter.sh 6.40rc7
  ```
* Re-downloading a specific release:
  ```shell
  ./ros-getter.sh 6.40.7 -r
  ```
  *or*
  ```shell
  ./ros-getter.sh --redownload 6.40rc7
  ```
