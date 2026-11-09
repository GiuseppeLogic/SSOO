#! /bin/bash

# Constantes:
FORMATO="%-10s %10s %10s\n"
PIDS=$(ps -A -o pid --no-header | sort -u | tr '\n' ' ')
SEGUNDOS_EJECUCION=-1
FICHEROS_ABIERTOS=-1

# Funciones:

help(){
  echo "Uso: $0 [-h | --help] [-p segundos] [-f ficheros_abiertos]"
  echo "  -h, --help    Muestra esta ayuda."
  echo "  -p SEGUNDOS   Filtra procesos ejecutándose desde hace N segundos o más."
  echo "  -f ARCHIVOS   Filtra procesos con N o más archivos abiertos."
}

error_exit(){
  echo "ERROR: ${1:-Error Desconocido.}" >&2
  exit 1
}

get_open_files(){
  lsof -p "$1" 2> "/dev/null" | awk 'NR>1' | wc -l
}

# Procesamiento de los parámetros posicionales:

while [[ -n "$1" ]]
do
  case "$1" in
    -h | --help )
      help
      exit 0
    ;;
    -p )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar un número válido tras -p."
      fi
      SEGUNDOS_EJECUCION=$1
    ;;
    -f )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar un número válido tras -f."
      fi
      FICHEROS_ABIERTOS=$1
    ;;
    * )
      error_exit "Argumento no válido: $1"
    ;;
  esac
  shift
done

# Comprobación del estado de ejecución:

if [[ "$SEGUNDOS_EJECUCION" -ne -1 ]];then
  if [[ ! "$SEGUNDOS_EJECUCION" =~ ^[0-9]+$ ]] || [[ "$SEGUNDOS_EJECUCION" -lt 0 ]];then
    error_exit "El valor de tiempo de ejecución ingresado no es válido."
  fi
fi

if [[ "$FICHEROS_ABIERTOS" -ne -1 ]];then
  if [[ ! "$FICHEROS_ABIERTOS" =~ ^[0-9]+$ ]] || [[ "$FICHEROS_ABIERTOS" -lt 0 ]];then
    error_exit "El valor de ficheros abiertos ingresado no es válido."
  fi
fi

# Lógica del programa:
SORT_CMD="sort -k2,2n"

printf "$FORMATO" "PID" "TIEMPO_EJECUCION" "N_ARCHIVOS"
for pid in $PIDS
do
  t_ejecucion=$(ps -p "$pid" --no-header -o etimes)

  if [[ -z "$t_ejecucion" ]];then
    continue
  fi

  imprimir=false

  if [[ "$SEGUNDOS_EJECUCION" -eq -1 && "$FICHEROS_ABIERTOS" -eq -1 ]];then
    imprimir=true
  else
    if [[ "$SEGUNDOS_EJECUCION" -gt -1 && "$t_ejecucion" -ge "$SEGUNDOS_EJECUCION" ]];then
      imprimir=true
    fi

    if [[ "$FICHEROS_ABIERTOS" -gt -1 && "$imprimir" == false ]];then
      n_archivos=$(get_open_files "$pid")
      if [[ "$n_archivos" -ge "$FICHEROS_ABIERTOS" ]];then
        imprimir=true
      fi
    fi
  fi

  if $imprimir;then
    if [[ -z "$n_archivos" ]];then
      n_archivos=$(get_open_files "$pid")
    fi
    printf "$FORMATO" "$pid" "$t_ejecucion" "$n_archivos"
  fi

  unset n_archivos

done | $SORT_CMD

exit 0