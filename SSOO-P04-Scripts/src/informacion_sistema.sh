#!/usr/bin/env bash

#  sysinfo - Un Script que informa del estado del sistema.


#### Constantes:

TITLE="Información del sistema"
AHORA=$(date +"%x %R %Z")
TIME_STAMP="Actualizado el $AHORA por $USER."

#### Estilos:

TEXT_BOLD=$'\x1b[1m'
TEXT_GREEN=$'\x1b[32m'
TEXT_RED=$'\x1b[31m'
TEXT_RESET=$'\x1b[0m' 
TEXT_ULINE=$'\x1b[4m'

#### Funciones:

is_root(){
	if [[ $USER == root ]]; then
		return 0
	else 
		return 1
	fi
}

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
	if is_root; then
		du -sh /home/* | sort -rh | sed 's|/home/||'
	else
		if [[ -d "/home/$USER" ]]; then
			du -sh /home/$USER | sed 's|/home/||'
		else
			echo "La ruta /home/$USER no es un directorio."
		fi
	fi
	echo	
}

environment_info(){
	echo "${TEXT_ULINE}Varibles de entorno:${TEXT_RESET}"
	echo "${TEXT_BOLD}PATH = ${TEXT_RESET}$PATH"
	echo 
	echo "${TEXT_BOLD}SHELL = ${TEXT_RESET}$SHELL"
	echo
}

check_security(){
	echo "${TEXT_ULINE}Comprobación de seguridad ('/etc/shadow'):${TEXT_RESET}"
	if [[ -f /etc/shadow && -r /etc/shadow ]]; then
		echo "${TEXT_RED} ES PELIGROSO QUE ACCEDA AL CONTENIDO DE ESTE ARCHIVO.${TEXT_RESET}"
	else
		echo "${TEXT_GREEN} NO CORRE NINGUN PELIGRO.${TEXT_RESET}"
	fi
	echo
}

check_hostname(){
	echo "${TEXT_ULINE}Comprobación del Hostname:${TEXT_RESET}"
	if [[ $HOSTNAME =~ [0-9] ]]; then
		echo "El Hostname $HOSTNAME contiene carácteres alfanuméricos."
	else
		echo "El Hostname $HOSTNAME solo contiene carácteres alfabéticos."
	fi
	echo
}

display_info(){
	echo "${TEXT_ULINE}Información sobre el entorno gráfico:${TEXT_RESET}"
	if [[ ! -z $DISPLAY ]]; then
		echo "${TEXT_GREEN} EXISTE ENTORNO GRÁFICO.${TEXT_RESET}"
	else 
		echo "${TEXT_RED} NO HAY ENTORNO GRÁFICO${TEXT_RESET}"
	fi
	echo
}

check_process(){
	echo "${TEXT_ULINE}Información sobre los procesos que más memoria consumen:${TEXT_RESET}"
	ps -eo pid,comm,%mem,rss --sort=-%mem | head -n 8
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
environment_info
check_security
check_hostname
display_info
check_process

exit 0
