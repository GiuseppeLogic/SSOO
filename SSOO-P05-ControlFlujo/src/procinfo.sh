#!/bin/bash

# Constantes.
SEGUNDOS_EJECUCION=0
FICHEROS_ABIERTOS=0
PIDS=$(ps -A -o pid --no-header)
FORMATO="%-10s %-20s %-15s\n"

# Funciones.
usage(){
  echo "Usage: $0 [-h | --help] [ -p NSegundos ] [ -f NFicherosAbiertos ]"
}

error_exit(){
  echo "$1" 1>&2
  exit 1
}

get_open_files(){
  lsof -p "$1" 2>/dev/null | awk 'NR > 1' | wc -l
}

# Procesamiento de la línea de comandos.
while [[ $1 != "" ]]
do
  case "$1" in
    -h | --help )
      usage
      exit 0
    ;;
    -p )
      shift
      if [[ "$1" == "" || "$1" == -* ]];then
        error_exit "Error: Falta la cantidad mínima de segundos en ejecución de los procesos."
      fi
      SEGUNDOS_EJECUCION=$1
    ;;
    -f )
      shift
      if [[ "$1" == "" || "$1" == -* ]];then
        error_exit "Error: Falta la cantidad mínima de ficheros abiertos."
      fi
      FICHEROS_ABIERTOS=$1
    ;;
    -* )
      usage
      error_exit "Error: Opción no reconocida."
    ;;
    * )
      error_exit "Error: Argumento no conocido."
    ;;
  esac
  shift
done

# Lógica del programa.
SORT_CMD="sort -k2,2n"

printf "$FORMATO" "PID" "TIEMPO_EJECUCION(s)" "N_ARCHIVOS"

for id in $PIDS
do
  t_ejecucion=$(ps --no-header -p "$id" -o etimes)
  
  if [[ -z "$t_ejecucion" ]]; then
      continue
  fi

  t_ejecucion=$(echo "$t_ejecucion" | tr -d ' ')

  imprimir=false

  if [[ "$SEGUNDOS_EJECUCION" -eq 0 && "$FICHEROS_ABIERTOS" -eq 0 ]]; then
      imprimir=true
  else
      if [[ "$SEGUNDOS_EJECUCION" -gt 0 && "$t_ejecucion" -ge "$SEGUNDOS_EJECUCION" ]]; then
          imprimir=true
      fi
      
      if [[ "$FICHEROS_ABIERTOS" -gt 0 && "$imprimir" == false ]]; then
          n_archivos=$(get_open_files "$id")
          if [[ "$n_archivos" -ge "$FICHEROS_ABIERTOS" ]]; then
              imprimir=true
          fi
      fi
  fi

  if $imprimir ; then
      if [[ -z "$n_archivos" ]]; then
          n_archivos=$(get_open_files "$id")
      fi
      printf "$FORMATO" "$id" "$t_ejecucion" "$n_archivos"
  fi
  
  unset n_archivos
  
done | $SORT_CMD

exit 0