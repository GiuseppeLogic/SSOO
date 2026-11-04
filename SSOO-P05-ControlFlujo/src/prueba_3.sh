#! /bin/bash

# Constantes:
USERS=$(w | awk 'NR>2 {print $1}' | sort -u | tr '\n' ' ')
FORMATO="%-18s %10s %10s %10s %12s\n"
PROC_MAX=-1
USA_EXPRESION_REGULAR=0
EXPRESION_REGULAR=""
SORT=0
INACTIVO=0
MEMORIA_MINIMA=0
USA_MEMORIA_MINIMA=0

# Funciones:
error_exit(){
  echo "ERROR: ${1:-Error Desconocido.}" >&2 
  exit 1
}

usage(){
  echo "Uso: proc_mon [-h | --help] [-c filtro_comando] [-i] [--inactive] [-m min_mb] [-s] [--sort]"
}

get_id_user(){
  id -u "$1" 2> "/dev/null"
}

number_process(){
  if [[ "$USA_EXPRESION_REGULAR" -eq 1 ]];then
    ps -u "$1" -o comm --no-header 2> "/dev/null" | awk -v reg="$EXPRESION_REGULAR" '$0 ~ reg {suma++} END {print suma+0}'
  else
    ps -u "$1" --no-header 2> "/dev/null" | wc -l
  fi
}

memoria_total_mb(){
  if [[ "$USA_EXPRESION_REGULAR" -eq 1 ]];then
    ps -u "$1" -o rss,comm --no-header 2> "/dev/null" | awk -v reg="$EXPRESION_REGULAR" '$2 ~ reg {suma += $1} END {print int(suma/1024)}'
  else
    ps -u "$1" --no-header -o rss 2> "/dev/null" | awk '{suma += $1} END {print int(suma/1024)}'
  fi
}

memoria_maxima(){
  if [[ "$USA_EXPRESION_REGULAR" -eq 1 ]];then
    ps -u "$1" -o pid,rss,comm --no-header 2> "/dev/null" | awk -v reg="$EXPRESION_REGULAR" '$3 ~ reg && $2 > max_rss { max_rss = $2; pid_max = $1 } END { print (pid_max ? pid_max : "NA") }'
  else
    ps -u "$1" --no-header -o pid,rss 2> "/dev/null" | awk '$2 > max_rss { max_rss = $2; pid_max = $1 } END { print (pid_max ? pid_max : "NA") }' 
  fi
}

# Procesamiento de parámetros posicionales:
while [[ -n "$1" ]]
do
  case "$1" in
    -h | --help )
      usage
      exit 0
    ;;
    -c )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar una expresión regular válida."
      fi
      EXPRESION_REGULAR="$1"
      USA_EXPRESION_REGULAR=1
    ;;
    -s | --sort )
      SORT=1
    ;;
    -i | --inactive ) 
      INACTIVO=1
    ;;
    -m )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar un número mínimo de memoria."
      fi
      MEMORIA_MINIMA="$1"
      USA_MEMORIA_MINIMA=1
    ;;
    * ) 
      error_exit "Argumento $1 no es válido."
    ;;
  esac
  shift
done

# Comprobación del estado de ejecución del programa:
if [[ -n "$PROC_MON_MAX" ]];then
  if [[ ! "$PROC_MON_MAX" =~ ^[0-9]+$ ]];then
    error_exit "La variable de entorno PROC_MON_MAX no es válida."
  else
    PROC_MAX="$PROC_MON_MAX"
  fi
fi

if [[ "$USA_MEMORIA_MINIMA" -eq 1 ]];then
  if [[ ! "$MEMORIA_MINIMA" =~ ^[0-9]+$ ]];then
    error_exit "El mínimo de memoria debe ser un entero positivo."
  fi
fi

# Lógica del programa:
SORT_CMD="sort -k1,1"

if [[ "$SORT" -eq 1 ]];then
  SORT_CMD="sort -k4,4nr -k1,1"
fi

if [[ "$INACTIVO" -eq 1 ]];then
  TODOS_USUARIOS=$(awk -F ':' '{print $1}' /etc/passwd | sort -u)
  USUARIOS_ACTIVOS=$(w | awk 'NR>2 {print $1}' | sort -u)

  USERS=$(comm -23 <(echo "$TODOS_USUARIOS") <(echo "$USUARIOS_ACTIVOS"))
fi

printf "$FORMATO" "USUARIO" "UID" "N_PROCESOS" "MEM_TOTAL_MB" "PID_MAX_MEM"

for usuario in $USERS
do
  imprime=true
  memoria_mb=$(memoria_total_mb "$usuario")

  if [[ "$PROC_MAX" -ne -1 && "$memoria_mb" -gt "$PROC_MAX" ]];then
    imprime=false
  fi

  if [[ "$USA_MEMORIA_MINIMA" -eq 1 && "$memoria_mb" -lt "$MEMORIA_MINIMA" ]];then
    imprime=false
  fi

  if "$imprime";then
    printf "$FORMATO" "$usuario" "$(get_id_user "$usuario")" "$(number_process "$usuario")" "$memoria_mb" "$(memoria_maxima "$usuario")"
  fi

done | $SORT_CMD

exit 0
