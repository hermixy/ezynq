#!/bin/bash

#get the current script path
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

#constants
UBOOT_TREE="$SCRIPTPATH/u-boot-tree"
CONFIGS="include/configs"
EZYNQ="ezynq"
REPO_DIR_NAME=u-boot-xlnx

SUFFIX=".orig"

INITENV="initenv"
OVERWRITE_INITENV=1
CROSS_COMPILE="arm-poky-linux-gnueabi-"
COMPILE_PATH="/opt/poky/1.4/sysroots/x86_64-pokysdk-linux/usr/bin/armv7a-vfp-neon-poky-linux-gnueabi/"

echo "Step 1: Cloning Xilinx's u-boot repository (master-next branch)"
if [ ! -d "$REPO_DIR_NAME/.git" ]; then
  git clone -b master-next https://github.com/Xilinx/u-boot-xlnx.git "$REPO_DIR_NAME"
else
  echo "  Already there"
fi

echo "Step 2: Checking out u-boot version with the hash 'e1808144fdbc79159b72318e6eb8bcab03fd9bf4'"
cd "$REPO_DIR_NAME"
git checkout e1808144fdbc79159b72318e6eb8bcab03fd9bf4

echo "Step 3: Merging ezynq with u-boot"

echo "Step 3a: Creating symbolic link for the root folder"
if [ ! -h $EZYNQ ]; then
  ln -s $SCRIPTPATH $EZYNQ
fi

echo "Step 3b: Creating symbolic link for the 'ezynq' folder"
if [ ! -h "$CONFIGS/$EZYNQ" ]; then
  ln -s "$UBOOT_TREE/$CONFIGS/$EZYNQ" $CONFIGS
fi

echo "Step 3c: Creating symbolic links for separate files (a suffix is added to the originals)"
for SRC in $(find $UBOOT_TREE -type f -not -path "$UBOOT_TREE/$CONFIGS/$EZYNQ/*")
do
  LINK=$(echo $SRC | sed "s:^$UBOOT_TREE/::")
  #echo "$SRC | $LINK"
  if [ ! -h $LINK ]; then
    ln -s -S $SUFFIX $SRC $LINK
  fi
done

echo "Step 4: Creating initenv script"
if [ -f $INITENV ]; then
    read -p "Overwrite initenv? (y/n) " yn
    if [ ! $yn = "y" ]; then
      OVERWRITE_INITENV=0;
    fi
fi

if [ $OVERWRITE_INITENV = 1 ] ; then
  echo "#!/bin/sh
export CROSS_COMPILE=$CROSS_COMPILE
export PATH=$COMPILE_PATH:\$PATH" > $INITENV
  #exec permissions are not required for source
  #chmod +x $INITENV 
fi

if [ ! -d $COMPILE_PATH ] ; then
  echo "  WARNING: Please edit initenv accordingly to your cross compiler path"
fi

echo "DONE"