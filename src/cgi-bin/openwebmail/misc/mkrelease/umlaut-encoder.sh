#!/bin/bash
#
# Script for transcoding german umlauts to HTML encodings
#
# author: Martin Bronk (Martin AT Bronk.de)

template_files=`ls *\.template`

for file in ${template_files}; do
  cat ${file} | \
   sed s/"�"/"\&auml;"/g | \
   sed s/"�"/"\&Auml;"/g | \
   sed s/"�"/"\&ouml;"/g | \
   sed s/"�"/"\&Ouml;"/g | \
   sed s/"�"/"\&uuml;"/g | \
   sed s/"�"/"\&Uuml;"/g | \
   sed s/"�"/"\&szlig;"/g  \
   > ${file}.tmp
  mv ${file}.tmp ${file}
  echo "${file} encoded."
done

