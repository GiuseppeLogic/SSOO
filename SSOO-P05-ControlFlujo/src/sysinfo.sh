#!/usr/bin/env bash

#  sysinfo - Un Script que informa del estado del sistema.


#### Constantes:

TITLE="Información del sistema"
AHORA=$(date +"%x %R %Z")
TIME_STAMP="Actualizado el $AHORA por $USER."

filename="../docs/sysinfo.txt"
interactive=0
mostrar_pantalla="S"
sobreescribir="S"

#### Estilos:

TEXT_BOLD=$'\x1b[1m'
TEXT_GREEN=$'\x1b[32m'
TEXT_RED=$'\x1b[31m'
TEXT_RESET=$'\x1b[0m' 
TEXT_ULINE=$'\x1b[4m'

#### Funciones:


usage(){
	echo "usage: sysinfo [-f filename] [-i] [-h]"
}

write_page(){
	cat << _EOF_

=== $TEXT_BOLD$TITLE $HOSTNAME$TEXT_RESET ===

$(system_info)

$(show_uptime)

$(drive_space)

$(home_space)

$(environment_info)

$(check_security)

$(check_hostname)

$(display_info)

$(check_process)

$(process_user)

$TEXT_GREEN$TIME_STAMP$TEXT_RESET

_EOF_
}

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
}

show_uptime(){
	echo "${TEXT_ULINE}Tiempo de encendido del sistema:${TEXT_RESET}"
	uptime	
}

drive_space(){
	echo "${TEXT_ULINE}Espacio ocupado por el sistema:${TEXT_RESET}"
	df
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
}

environment_info(){
	echo "${TEXT_ULINE}Varibles de entorno:${TEXT_RESET}"
	echo "${TEXT_BOLD}PATH = ${TEXT_RESET}$PATH"
	echo 
	echo "${TEXT_BOLD}SHELL = ${TEXT_RESET}$SHELL"
}

check_security(){
	echo "${TEXT_ULINE}Comprobación de seguridad ('/etc/shadow'):${TEXT_RESET}"
	if [[ -f /etc/shadow && -r /etc/shadow ]]; then
		echo "${TEXT_RED} ES PELIGROSO QUE ACCEDA AL CONTENIDO DE ESTE ARCHIVO.${TEXT_RESET}"
	else
		echo "${TEXT_GREEN} NO CORRE NINGUN PELIGRO.${TEXT_RESET}"
	fi
}

check_hostname(){
	echo "${TEXT_ULINE}Comprobación del Hostname:${TEXT_RESET}"
	if [[ $HOSTNAME =~ [0-9] ]]; then
		echo "El Hostname $HOSTNAME contiene carácteres alfanuméricos."
	else
		echo "El Hostname $HOSTNAME solo contiene carácteres alfabéticos."
	fi
}

display_info(){
	echo "${TEXT_ULINE}Información sobre el entorno gráfico:${TEXT_RESET}"
	if [[ ! -z $DISPLAY ]]; then
		echo "${TEXT_GREEN} EXISTE ENTORNO GRÁFICO.${TEXT_RESET}"
	else 
		echo "${TEXT_RED} NO HAY ENTORNO GRÁFICO${TEXT_RESET}"
	fi
}

check_process(){
	echo "${TEXT_ULINE}Información sobre los procesos que más memoria consumen:${TEXT_RESET}"
	ps -eo pid,comm,%mem,rss --sort=-%mem | head -n 8
}

process_user(){
	num_process=$(ps -u $USER --no-header | wc -l)
	echo "${TEXT_ULINE}Información sobre los procesos del usuario $USER:${TEXT_RESET}"
	if [[ $num_process -gt 10 ]]; then
		echo "El usuario tiene más de 10 comandos en ejecución:"
		ps -u $USER  --no-header | sort -k 4
		echo "Cantidad total de comandos en ejecución: $num_process."
	else
		echo "El número de procesos de $USER es: $num_process"
	fi
}

if [[ $# -eq 0 ]];then
	write_page
	exit 0
fi

while [[ "$1" != "" ]];do
	case "$1" in
		-f | --file ) 
			shift
			filename=$1
			;;
		-i | --interactive )
			interactive=1
			;;
		-h | --help )
			usage
			exit
			;;
		* ) 
			usage
			exit 1
	esac 
	shift
done

if [[ $interactive -eq 1 ]];then
	read -p "Mostrar el informe del sistema en pantalla (S/N):" entrada_temporal
	mostrar_pantalla=${entrada_temporal:-$mostrar_pantalla}
	if [[ $mostrar_pantalla == "S" ]];then
		write_page
		exit 0
	else
		echo 
		read -p "Introduzca el nombre del archivo [$filename]:"  entrada_temporal
		filename=${entrada_temporal:-$filename}
		if [[ -e $filename && -f $filename ]];then
			read -p "El archivo de destino existe. ¿Sobreescribir? (S/N):" entrada_temporal
			sobreescribir=${entrada_temporal:-$sobreescribir}
			if [[ $sobreescribir == "S" ]];then
				write_page > $filename
				exit 0
			else
				exit 0
			fi
		else 
			echo "El archivo de destino no existe."
			exit 1
		fi
	fi
fi

write_page > $filename

exit 0
