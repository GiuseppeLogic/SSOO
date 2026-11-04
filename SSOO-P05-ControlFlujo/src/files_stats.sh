#!/bin/bash

# ==============================================================================
# OBJETIVO DEL SCRIPT
# Desarrollar un script en Bash que analice los ficheros de un directorio 
# específico y muestre el consumo de memoria de los procesos que los 
# mantienen abiertos.
#
# FUNCIONAMIENTO PRINCIPAL
# 1. Directorio por defecto: Si no se indican opciones, el script analizará 
#    el directorio /tmp.
# 2. Búsqueda de procesos: Para cada fichero ubicado en el directorio objetivo, 
#    el script utilizará el comando 'lsof' para identificar qué procesos lo 
#    tienen abierto.
# 3. Cálculo de memoria: Extrayendo el PID de la salida anterior, el script 
#    consultará y mostrará el porcentaje de memoria que está consumiendo cada 
#    uno de esos procesos.
# 4. Alcance: Esta acción se repetirá de forma iterativa para todos los 
#    ficheros contenidos en el directorio analizado.
#
# OPCIONES Y PARÁMETROS
#  -d <directorio> : Permite modificar el directorio de trabajo. Si se 
#                    proporciona esta opción, el script omitirá la búsqueda 
#                    en /tmp y analizará el directorio indicado por el usuario.
# ==============================================================================

# Constantes:
FORMATO="%-10s %10s\n"
INGRESA_DIRECTORIO=0
DIRECTORIO="/tmp"

# Funciones:
error_exit(){
  echo "ERROR: ${1:-Error Desconocido.}" >&2
  exit 1
}

lsof_instalado(){
  type lsof > "/dev/null" 2> "/dev/null"
}

directorio_existe(){
  if [[ ! -d "$1" ]];then
    error_exit "No existe el directorio $1."
  fi
}

# Procesamiento de parámetros posicionales:

while [[ -n "$1" ]]
do
  case "$1" in 
    -d )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar la ruta de un directorio."
      fi
      INGRESA_DIRECTORIO=1
      DIRECTORIO="$1"
    ;;
    * )
      error_exit "No es un argumento válido."
    ;;
  esac
  shift
done

# Comprobación del estado del programa:

if ! lsof_instalado;then
  error_exit "No se encuentra instalada la aplicación lsof."
fi

if [[ "$INGRESA_DIRECTORIO" -eq 1 ]];then
  directorio_existe "$DIRECTORIO"
fi

# Lógica del programa:
SORT_CMD="sort -k2,2nr"

PIDS=$(lsof +D"$DIRECTORIO" 2> "/dev/null" | awk 'NR>1 {print $2}' | sort -u | tr '\n' ' ')
printf "$FORMATO" PID MEMORIA
for pid in  $PIDS
do
  printf "$FORMATO" "$pid" $(ps -p "$pid" --no-header -o %mem | awk '{suma += $1} END {print (suma) ? suma"%" : 0"%"}')
done | $SORT_CMD

exit 0
