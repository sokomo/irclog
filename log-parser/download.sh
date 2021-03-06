#!/bin/bash

# Purpose: Download irssi logs from remotes
# Author : Anh K. Huynh (kyanh@viettug.org)
# Date   : 2012 Apr 14th
# License: Fair license

[[ -n "$_NO_DOWNLOAD" ]] && exit 0

cd archives \
&& {
  for f in archlinuxvn; do
    if [[ "$f" == "m1.archlinuxvn" ]]; then
      gunzip ./$f.log.gz
      rm -f ./$f.log.gz
    elif [[ -f ./$f.log.gz ]]; then
      echo ":: Decompressing $f.log.gz"
      gunzip ./$f.log.gz
    fi
    wait
    case $f in
      'archlinuxvn')     _R_="irc.archlinuxvn.m0" ;;
      'm1.archlinuxvn')  _R_="irc.archlinuxvn.m1" ;;
    esac
    echo ":: Info: Transferring file from $_R_"
    rsync -aessh --progress "${_R_}:~/irclogs/freenode/\#archlinuxvn.log" $f.log
    gzip $f.log
  done
}
