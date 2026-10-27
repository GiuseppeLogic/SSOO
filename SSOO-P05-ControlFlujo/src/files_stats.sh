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
DIRECTORIO="/tmp"
FORMATO="%-12s %10s" 

# Funciones:

error_system(){
  echo "ERROR: $1"
  exit 1
}

lsof_installed(){
  type lsof > /dev/null 2> /dev/null
}

directorio_existe(){
  if [[ ! -d "$1" ]];then
    error_system "No es un directorio válido."
  fi
}

# Procesamiento de parámetros posicionales.

while [[ -n "$1" ]]
do
  case "$1" in 
    -d )
      shift
      if [[ "$1" == "" || "$1" == -* ]];then 
        error_system "Tienes que ingresar un directorio válido."
      fi
      DIRECTORIO="$1"
    ;;
    * )
      error_system "No es un argumento válido."
    ;;
  esac
  shift
done


# Comprobación del estado de ejecución.

if ! lsof_installed; then
  error_system "Debe estar instalado el programa lsof."
fi

directorio_existe "$DIRECTORIO"

# Lógica del programa.
SORT="sort -k2,2nr"

PIDS=$(lsof +D"$DIRECTORIO"  2> /dev/null | awk 'NR>1 {print $2}' | sort -u )

printf "$FORMATO" PID MEMORIA 
echo
for pid in $PIDS
do 
  printf "$FORMATO" "$pid" $(ps -p "$pid" --no-header -o %mem |awk '{print ($1 == "") ? "0.0%" : $1"%"}')
  echo
done | $SORT

exit 0
