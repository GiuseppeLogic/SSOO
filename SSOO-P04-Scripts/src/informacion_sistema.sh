#!/usr/bin/env bash

#  sysinfo - Un Script que informa del estado del sistema.


#### Constantes:

TITLE="Información del sistema"
AHORA=$(date +"%x %R %Z")
TIME_STAMP="Actualizado el $AHORA por $USER."

#### Estilos:

TEXT_BOLD=$'\x1b[1m'
TEXT_GREEN=$'\x1b[32m'
TEXT_RESET=$'\x1b[0m' 
TEXT_ULINE=$'\x1b[4m'

#### Funciones:

system_info(){
	echo "${TEXT_ULINE}Versión del sistema:${TEXT_RESET}"
	uname -a
	echo
}

show_uptime(){
	echo "${TEXT_ULINE}Tiempo de encendido del sistema:${TEXT_RESET}"
	uptime	
	echo
}

drive_space(){
	echo "${TEXT_ULINE}Espacio ocupado por el sistema:${TEXT_RESET}"
	df
	echo
}

home_space(){
	echo "USADO	DIRECTORIO"
	if [[ $USER == root ]]; then
		du -sh /home/*  | sed 's|/home/||'
	else
		du -sh /home/$USER | sed 's|/home/||'
	fi
	echo	
}

cat << _EOF_

=== $TEXT_BOLD$TITLE $HOSTNAME$TEXT_RESET ===
$TEXT_GREEN$TIME_STAMP$TEXT_RESET

_EOF_

system_info
show_uptime
drive_space
home_space

exit 0
