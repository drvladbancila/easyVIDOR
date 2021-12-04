#!/bin/bash

function is_project_directory {
    if [[ -d src && -d quartus && -d arduino ]]; then
        echo 1
    else
        echo 0
    fi
}

function create_project {
    PROJ_DIR=$1
    PROJ_NAME=$2

    if [ ! -d "$PROJ_DIR/$PROJ_NAME" ]; then
        mkdir $PROJ_DIR/$PROJ_NAME
        unzip -q template.zip
        mv template/* $PROJ_DIR/$PROJ_NAME
        rm -rf template
    
        echo "[*] Project created successfully"
    else
        echo "[!] Error: $PROJ_DIR/$PROJ_NAME already exists"
    fi
}

function add_file {
    PROJ_PATH=$(pwd)
    FILE_PATH=$1
    FILENAME=$(basename $FILE_PATH)
    NEW_VHDL_STRING="set_global_assignment -name VHDL_FILE ../src/$FILENAME"
    
    if [ $(is_project_directory) == "1" ]; then
        if [[ -f "$FILE_PATH" && ! -f "src/$FILENAME" ]]; then
            cp $FILE_PATH $PROJ_PATH/src/
            echo $NEW_VHDL_STRING >> $PROJ_PATH/quartus/MKRVIDOR4000.qsf
            echo "[*] $FILENAME added successfully"
        else
            echo "[!] Error: $FILE_PATH does not exist or it was already added to the project"
        fi
    else
        echo "[!] Error: $PROJ_PATH is not the directory of a project"
    fi
}

function compile_project {
    PROJ_PATH=$(pwd)
    
    if ! [ -x $(command -v quartus_sh) ]; then
        echo "[!] Error: Quartus is not installed or PATH is not configured correctly"
    else
        QUARTUS_PATH=$PROJ_PATH/quartus
        quartus_sh --flow compile $QUARTUS_PATH/MKRVIDOR4000
        
        if [ -d $PROJ_PATH/quartus/output_files ]; then
            SOURCE="${BASH_SOURCE[0]}"
            SOURCE_DIR=$(dirname $SOURCE)
            python3 $SOURCE_DIR/tools/ReverseByte.py $QUARTUS_PATH/output_files/MKRVIDOR4000.ttf $QUARTUS_PATH/output_files/app.h
            mv $QUARTUS_PATH/output_files/app.h $PROJ_PATH/arduino
            
            echo "[*] Project compiled successfully"
        else
            echo "[!] Error: something went wrong during the compilation. No output folder"
        fi
    fi
}

function flash_project {
    PROJ_PATH=$(pwd)

    chmod +x $SOURCE_DIR/arduino-cli
    $SOURCE_DIR/tools/arduino-cli core install arduino:samd
    $SOURCE_DIR/tools/arduino-cli compile --fqbn arduino:samd:mkrvidor4000 $PROJ_PATH/arduino/arduino.ino
    $SOURCE_DIR/tools/arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:samd:mkrvidor4000 $PROJ_PATH/arduino/arduino.ino && echo "[*] The program was uploaded successfully"
}

SOURCE="${BASH_SOURCE[0]}"
SOURCE_DIR=$(dirname $SOURCE)

case $1 in
    create)
        create_project $2 $3
    ;;
    add_file)
        add_file $2
    ;;
    compile)
        compile_project
    ;;
    flash)
        flash_project
    ;;
    *)
        man ./man.1
    ;;
esac


