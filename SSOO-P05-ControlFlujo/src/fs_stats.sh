#! /bin/bash

# Constantes:
FORMATO="%-12s %10s %6s %12s\n"
MIN_USED_KB=${MIN_USED_KB:-""}
EXPREG=""
UNMOUNTED=0
TIPOS=$(df -T -P | awk 'NR>1 {print $2}' | sort -u | tr '\n' ' ')
LISTA_TIPOS=0
SORT=0

# Funciones:
usage(){
  echo "fs_stats [-h | --help] [-f regexp] [-u] [--unmounted] [-t tipo...] [-s] [--sort]"
}

error_exit(){
  echo "ERROR: $1"
  exit 1
}

df_is_installed(){
  type df > /dev/null 2> /dev/null
}

tipo_soportado(){
  grep "$1" /proc/filesystems > /dev/null 2> /dev/null
}

get_bloques(){
  df -T -t "$1" -P 2> /dev/null | awk 'NR>1 {suma += $3} END {print (suma ? suma : 0)}' 
}

get_montajes(){
  if [[ -n "$EXPREG" ]];then
    df -T -t "$1" -P 2> /dev/null | awk -v expreg="$EXPREG" 'NR>1 && $7 ~ expreg' | wc -l 
  else
    df -T -t "$1" -P 2> /dev/null | awk 'NR>1' | wc -l 
  fi
}

get_used(){
  df -T -t "$1" -P 2> /dev/null | awk 'NR>1 {suma += $4} END {print (suma ? suma : 0)}'
}

# Procesamiento de parámetros posicionales:
while [[ -n "$1" ]]; do
  case "$1" in
    -h | --help )
      usage
      exit 0
    ;;
    -f )
      shift
      if [[ -n "$1" && "$1" != -* ]]; then
        EXPREG=$1
      else
        error_exit "Se debe ingresar una expresión regular."
      fi
    ;;
    -s | --sort ) 
      SORT=1
    ;;
    -u | --unmounted )
      UNMOUNTED=1
    ;;
    -t )
      shift
      if [[ -n "$1" && "$1" != -* ]]; then
        TIPOS=""
        LISTA_TIPOS=1
        while [[ -n "$1" && "$1" != -* ]]; do
          TIPOS="$TIPOS $1"
          shift
        done 
        continue 
      else
        error_exit "No ha ingresado una lista de tipos."
      fi
    ;;
    -* )
      error_exit "No se reconoce la opción."
    ;;
    * )
      error_exit "Argumento no válido."
    ;;
  esac
  shift
done

# Comprobación del estado de programación:

if ! df_is_installed;then
  error_exit "Tienes que instalar df para continuar."
fi

if [[ -n "$MIN_USED_KB" ]]; then
  if [[ ! "$MIN_USED_KB" =~ ^[0-9]+$ ]]; then
    error_exit "La variable de entorno MIN_USED_KB debe ser un valor numérico mayor o igual que cero."
  fi
fi

for tipo in $TIPOS
do 
  if ! tipo_soportado $tipo;then
    error_exit "No se soporta el tipo $tipo."
  fi
done

# Lógica del programa.
SORT_CMD="sort -k1,1"

if [[ "$SORT" -eq 1 ]];then 
  SORT_CMD="sort -k4,4nr -k1,1"
fi

if [[ "$UNMOUNTED" -eq 1 ]]; then 
  TODOS_LOS_TIPOS=$(cat /proc/filesystems | awk '{print $NF}' | sort -u)
  TIPOS_MONTADOS=$(df -T -P | awk 'NR>1 {print $2}' | sort -u)

  TIPOS_NO_MONTADOS=$(comm -23 <(echo "$TODOS_LOS_TIPOS") <(echo "$TIPOS_MONTADOS"))

  if [[ "$LISTA_TIPOS" -eq 1 ]]; then
    TIPOS_FILTRO=""
    for tipo in $TIPOS; do
      if echo "$TIPOS_NO_MONTADOS" | grep -q "^${tipo}$"; then
        TIPOS_FILTRO="$TIPOS_FILTRO $tipo"
      fi
    done
    TIPOS=$TIPOS_FILTRO
  else
    TIPOS=$(echo "$TIPOS_NO_MONTADOS" | tr '\n' ' ')
  fi
fi

printf "$FORMATO" TIPO_FS N_MONTAJES TOTAL_KB USADO_KB
for tipo in $TIPOS
do 
  if [[ -n "$MIN_USED_KB" ]];then
    if [[ $(df -T -t "$tipo" -P | awk 'NR>1 {suma += $4} END {print (suma ? suma : 0)}') -gt "$MIN_USED_KB" ]];then
      printf "$FORMATO" "$tipo" $(get_montajes "$tipo") $(get_bloques "$tipo") $(get_used "$tipo")
    fi
  else
      printf "$FORMATO" "$tipo" "$(get_montajes "$tipo")"  "$(get_bloques "$tipo")"  "$(get_used "$tipo")"
  fi
done | $SORT_CMD

exit 0