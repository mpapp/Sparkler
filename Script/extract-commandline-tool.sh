#!/bin/bash

cp -v "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/${EXECUTABLE_NAME}" "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_NAME}"

mkdir -p "${DSTROOT}/bin"
mkdir -p "${DSTROOT}/Frameworks"
cp -v "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_NAME}" "${DSTROOT}/bin/${EXECUTABLE_NAME}"

rm -rfv "${DSTROOT}/Frameworks"
cp -rv "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/../Frameworks" "${DSTROOT}/Frameworks"

ln -fs "${DSTROOT}/bin/${EXECUTABLE_NAME}" "/usr/local/bin/${EXECUTABLE_NAME}"
