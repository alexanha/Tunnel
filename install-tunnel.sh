#!/bin/sh

cd "`dirname \"$0\"`"

if [ "x${MATHEMATICA_USERBASE}x" = "xx" ]
then
	if [ -d "$HOME/Library/Mathematica" ]
	then
		# OS X
		MATHEMATICA_USERBASE="$HOME/Library/Mathematica"
	else
		# Linux
		MATHEMATICA_USERBASE="$HOME/.Mathematica"
	fi
fi

# install kernel init file
mkdir -v -p "${MATHEMATICA_USERBASE}/Kernel"
cp -p -f -v scripts/tunnel.m "${MATHEMATICA_USERBASE}/Kernel"

# install shell script helpers
mkdir -v -p "${MATHEMATICA_USERBASE}/FrontEnd"
cp -p -f -v scripts/tunnel.sh "${MATHEMATICA_USERBASE}/FrontEnd"
chmod +x "${MATHEMATICA_USERBASE}/FrontEnd/tunnel.sh"
cp -p -f -v scripts/tunnel_sub.sh "${MATHEMATICA_USERBASE}/FrontEnd"
chmod +x "${MATHEMATICA_USERBASE}/FrontEnd/tunnel_sub.sh"
cp -p -f -v scripts/tunnel_qsub.sh "${MATHEMATICA_USERBASE}/FrontEnd"
chmod +x "${MATHEMATICA_USERBASE}/FrontEnd/tunnel_qsub.sh"
cp -p -f -v scripts/tunnel_qsub_loadmath.sh "${MATHEMATICA_USERBASE}/FrontEnd"
chmod +x "${MATHEMATICA_USERBASE}/FrontEnd/tunnel_qsub_loadmath.sh"
