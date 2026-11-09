#! /bin/bash

# Constantes:
USERS=$(w | awk 'NR>2 {printf $1}' | tr '\n' ' ')
MIN_RSS=${MIN_RSS_KB:-""}
EXPREG=""
LISTA_USERS=0
SORT=0
DISCONNECTED=0
USERS_DISCONNECTED=""
FORMATO="%-12s %10s %6s %12s\n"


# Funciones:

usage(){
  echo "Usage: proc_stats [-h | --help] [-f regexp] [-d] [--disconnected] [-u usuario...] [-s] [--sort]"
}

error_exit(){
  echo "ERROR: $1"
  exit 1
}

get_user_id(){
  id -u "$1" 2> /dev/null
}

ps_installed(){
  type ps > /dev/null 2> /dev/null
}

user_exist(){
  id $1 > /dev/null 2> /dev/null
}

number_process(){
  if [[ -n "$MIN_RSS" && -z "$EXPREG" ]]; then
    ps -u "$1" --no-header -o rss | awk -v min="$MIN_RSS" '$1 > min' | wc -l
  elif [[ -z "$MIN_RSS" && -n "$EXPREG" ]]; then
    ps -u "$1" --no-header -o comm | awk -v expreg="$EXPREG" '$1 ~ expreg' | wc -l
  elif [[ -n "$MIN_RSS" && -n "$EXPREG" ]]; then
    ps -u "$1" --no-header -o rss,comm | awk -v expreg="$EXPREG" -v min="$MIN_RSS" '$2 ~ expreg && $1 > min' | wc -l
  else
    ps -u "$1" --no-header -o pid | wc -l
  fi
}


memory_process(){
  if [[ -n "$MIN_RSS" && -z "$EXPREG" ]]; then
    ps -u "$1" --no-header -o rss | awk -v min="$MIN_RSS" '$1 > min {suma += $1} END {print (suma ? suma : 0)}'
  elif [[ -z "$MIN_RSS" && -n "$EXPREG" ]]; then
    ps -u "$1" --no-header -o rss,comm | awk -v expreg="$EXPREG" '$2 ~ expreg {suma += $1} END {print (suma ? suma : 0)}'
  elif [[ -n "$MIN_RSS" && -n "$EXPREG" ]]; then
    ps -u "$1" --no-header -o rss,comm | awk -v expreg="$EXPREG" -v min="$MIN_RSS" '$2 ~ expreg && $1 > min {suma += $1} END {print (suma ? suma : 0)}'
  else
    ps -u "$1" --no-header -o rss | awk '{suma += $1} END {print (suma ? suma : 0)}'
  fi
}


# Procesamiento de los parámetros posicionales.
while [[ $# -gt 0 ]]
do 
  case "$1" in
    -h | --help  )
      usage
      exit 0
    ;;
    -s | --sort  )
      SORT=1
      shift
    ;;
    -d | --disconnected  )
      DISCONNECTED=1
      shift
    ;;
    -f )
      shift
      if [[ "$1" == "" || "$1" == -* ]];then
        error_exit "Error: Falta la expresión regular."
      fi
      EXPREG=$1
      shift
    ;;
    -u | --user )
      shift
      USERS=""
      LISTA_USERS=1
      if [[ "$1" == "" || "$1" == -* ]];then
        error_exit "Error: Falta la lista de usuarios."
      fi
      while [[ "$1" != "" && "$1" != -* ]]
      do
        USERS="$USERS $1"
        shift
      done
    ;;
    -* )
      error_exit "No se reconoce esa opción."
    ;;
    * )
      error_exit "No se reconoce el argumento."
  esac
done


# Comrpobaciones del programa.

if ! ps_installed;then
  error_exit "Se debe tener instalado el programa ps."
fi

for usuario in $USERS;
do
  if ! user_exist $usuario;then
    error_exit "El usuario $usuario no existe."
  fi
done

if [[ -n "$MIN_RSS" ]]; then
  if ! [[ "$MIN_RSS" =~ ^[0-9]+$ ]]; then
    error_system "La variable MIN_RSS_KB debe ser un valor numérico mayor o igual a 0."
  fi
fi

# Lógica del programa.
SORT_CMD="sort -k1,1"

if [[ "$SORT" == "1" ]];then
  SORT_CMD="sort -k4,4nr -k1,1"
fi


if [[ "$DISCONNECTED" == "1" ]];then
  USUARIOS_CONECTADOS=$(w | awk 'NR > 2 {print $1}' | sort -u)
  TODOS_LOS_USUARIOS=$(cut -d':' -f1 /etc/passwd | sort -u)

  SOLO_DESCONECTADOS=$(comm -23 <(echo "$TODOS_LOS_USUARIOS") <(echo "$USERS_CONECTADOS"))

  if [[ $LISTA_USERS  == "1" ]];then
    LISTA_USERS_DESCONECTADOS=""
    for usuario in $USERS
    do
      if echo "$SOLO_DESCONECTADOS" | grep -q "^${usuario}$";then
        LISTA_USERS_DESCONECTADOS="$LISTA_USERS_DESCONECTADOS $usuario"
      fi
    done
    USERS=$LISTA_USERS_DESCONECTADOS
  else
    USERS=$(echo "$SOLO_DESCONECTADOS" | tr '\n' ' ')
  fi
fi


printf "$FORMATO" USUARIO UID N_PROCESOS MEMORIA_KB
for usuario in $USERS;
do
  printf "$FORMATO" $usuario  $(get_user_id "$usuario") $(number_process "$usuario") $(memory_process "$usuario")
done

exit 0