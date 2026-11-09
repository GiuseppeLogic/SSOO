#! /bin/bash

# Constantes:
FORMATO="%-12s %10s %10s %12s\n"
SORT=0
EXPRESION_REGULAR=""
UNMOUNTED=0
INGRESA_TIPOS=0
TIPOS=$(df -T -P | awk 'NR>1 {print $2}' | sort -u | tr '\n' ' ')
MIN_USED_KB=${MIN_USED_KB:-""}
INGRESA_VARIABLE=0

if [[ -n "$MIN_USED_KB" ]];then
  INGRESA_VARIABLE=1
fi


# Funciones:
help(){
  echo "fs_stats [-h | --help] [-f regexp] [-u] [--unmounted] [-t tipo...] [-s] [--sort]"
  exit 0
}

df_instalado(){
  type df > "/dev/null"  2> "/dev/null"
}

error_exit(){
  echo "ERROR: $1" >&2
  exit 1
}

tipo_soportado(){
  grep "$1" /proc/filesystems > /dev/null 2> /dev/null
}

n_montajes(){
  if [[ -n "$MIN_USED_KB" && -n "$EXPRESION_REGULAR" ]];then
    df -P -t "$1" 2> /dev/null | awk -v min_used="$MIN_USED_KB" -v reg="$EXPRESION_REGULAR" 'NR>1 && $3 > min_used && $NF ~ reg {suma += 1} END {print (suma) ? suma : 0}'
  elif [[ -n "$MIN_USED_KB" ]];then
    df -P -t "$1" 2> /dev/null | awk -v min_used="$MIN_USED_KB" 'NR>1 && $3 > min_used {suma += 1} END {print (suma) ? suma : 0}'
  elif [[ -n "$EXPRESION_REGULAR" ]];then
    df -P -t "$1" 2> /dev/null | awk -v reg="$EXPRESION_REGULAR" 'NR>1 && $NF ~ reg {suma += 1} END {print (suma) ? suma : 0}'
  else
    df -P -t "$1" 2> /dev/null | awk  'NR>1' | wc -l
  fi
}

total_kb(){
  if [[ -n "$MIN_USED_KB" && -n "$EXPRESION_REGULAR" ]];then
    df -P -t "$1" 2> /dev/null | awk -v min_used="$MIN_USED_KB" -v reg="$EXPRESION_REGULAR" 'NR>1 && $3 > min_used && $NF ~ reg {suma += $2} END {print (suma) ? suma : 0}'
  elif [[ -n "$MIN_USED_KB" ]];then
    df -P -t "$1" 2> /dev/null | awk -v min_used="$MIN_USED_KB" 'NR>1 && $3 > min_used {suma += $2} END {print (suma) ? suma : 0}'
  elif [[ -n "$EXPRESION_REGULAR" ]];then
    df -P -t "$1" 2> /dev/null | awk -v reg="$EXPRESION_REGULAR" 'NR>1 && $NF ~ reg {suma += $2} END {print (suma) ? suma : 0}'
  else
    df -P -t "$1" 2> /dev/null | awk  'NR>1 {suma += $2} END {print (suma) ? suma : 0}' 
  fi
}

usado_kb(){
  if [[ -n "$MIN_USED_KB" && -n "$EXPRESION_REGULAR" ]];then
    df -P -t "$1"  2> /dev/null | awk -v min_used="$MIN_USED_KB" -v reg="$EXPRESION_REGULAR" 'NR>1 && $3 > min_used && $NF ~ reg {suma += $3} END {print (suma) ? suma : 0}'
  elif [[ -n "$MIN_USED_KB" ]];then
    df -P -t "$1" 2> /dev/null | awk -v min_used="$MIN_USED_KB" 'NR>1 && $3 > min_used {suma += $3} END {print (suma) ? suma : 0}'
  elif [[ -n "$EXPRESION_REGULAR" ]];then
    df -P -t "$1" 2> /dev/null | awk -v reg="$EXPRESION_REGULAR" 'NR>1 && $NF ~ reg {suma += $3} END {print (suma) ? suma : 0}'
  else
    df -P -t "$1" 2> /dev/null | awk  'NR>1 {suma += $3} END {print (suma) ? suma : 0}' 
  fi
}

# Procesamiento de parámetros posicionales:
while [[ -n "$1" ]]
do
  case "$1" in
    -s | --sort ) 
      SORT=1
    ;;
    -h | --help )
      help
    ;;
    -u | --unmounted )
      UNMOUNTED=1
    ;;
    -t )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Se debe ingresar al menos un tipo del sistema."
      fi
      INGRESA_TIPOS=1
      TIPOS=""
      while [[ -n "$1" && "$1" != -* ]]
      do
        TIPOS="$TIPOS $1"
        shift
      done
      continue
    ;;
    -f )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar una expresión regular."
      fi
      EXPRESION_REGULAR="$1"
    ;;
    -* ) 
      error_exit "Alguna opción no es válida."
    ;;
    * )
      error_exit "Algun argumento no es válido."
  esac
  shift
done
   

# Comprobación del estado de ejecución:
if ! df_instalado;then
  error_exit "El programa tiene que tener instalado df"
fi

if [[ "$INGRESA_VARIABLE" -eq 1 ]]; then
  if ! [[ "$MIN_USED_KB" =~ ^[0-9]+$ ]] || [[ "$MIN_USED_KB" -le 0 ]]; then
    error_exit "La variable de entorno debe ser un número mayor a cero."
  fi
fi

if [[ "$INGRESA_TIPOS" -eq 1 ]];then
  for tipo in $TIPOS
  do 
    if ! tipo_soportado $tipo;then
      error_exit "No se soporta el tipo $tipo."
    fi
  done
fi

# Lógica del programa:
SORT_CMD="sort -k1,1"

if [[ "$SORT" -eq 1 ]];then
  SORT_CMD="sort -k4,4nr"
fi

if [[ "$UNMOUNTED" -eq 1 ]];then
  TODOS_LOS_TIPOS=$(cat /proc/filesystems | awk '{print $2}' | sort -u)
  TIPOS_MONTADOS=$(df -T -P | awk 'NR>1 {print $2}' | sort -u)

  TIPOS_NO_MONTADOS=$(comm -23 <(echo "$TODOS_LOS_TIPOS") <(echo "$TIPOS_MONTADOS"))

  if [[ "$INGRESA_TIPOS" -eq 1 ]];then
    TIPOS_AUX=""
    for tipo in $TIPOS
    do
      if echo "$TIPOS_NO_MONTADOS" | grep -q "^${tipo}$";then
        TIPOS_AUX="$TIPOS_AUX $tipo"
      fi
    done
    TIPOS="$TIPOS_AUX"
  else
    TIPOS=$(echo "$TIPOS_NO_MONTADOS" | tr '\n' ' ')
  fi
fi

printf "$FORMATO" TIPO_FS N_MONTAJES TOTAL_KB USADO_KB
for tipo in $TIPOS
do
  printf "$FORMATO" "$tipo" $(n_montajes "$tipo") $(total_kb "$tipo")  $(usado_kb "$tipo")
done | $SORT_CMD

exit 0