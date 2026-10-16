#! /bin/bash

# Constantes.
SORT=0
USERS="$(w | awk 'NR > 2 {print $1}' | sort -u | tr '\n' ' ')"
USERS_NO_CONECTADOS=""
LISTA_USERS=0
EXPREG=""
OFFLINE=0
DIR="${OPEN_FILES_FOLDER:-""}"
FORMATO="%-12s %10s %6s %12s\n"

# Funciones.
usage(){
  echo "Usage: open_files [-h | --help] [-f regexp] [-o] [--offline]  [-u usuario ...]  [-s ] [-–sort]"
}

error_exit(){
  echo $1
  exit 1
}

directorio_existe(){
  if [[ -d "$1" ]];then
    return 0
  else
    return 1
  fi
}

archivo_existe(){
  if [[ -f "$1" ]];then
    return 0
  else
    return 1
  fi
}

lsof_es_instalado(){
  type lsof > /dev/null 2> /dev/null
}

user_existe(){
  id "$1" > /dev/null 2> /dev/null
}

get_user_id(){
  id -u "$1" 2> /dev/null
}

get_open_files(){
  if [[ -n "$DIR" && -n "$EXPREG" ]]; then 
    lsof -u "$1" -a +D "$DIR" 2>/dev/null | awk -v expr="$EXPREG" 'NR > 1 && $5 == "REG" && $9 ~ expr' | wc -l
  elif [[ -n "$DIR" ]]; then
    lsof -u "$1" -a +D "$DIR" 2>/dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
  elif [[ -n "$EXPREG" ]]; then
    lsof -u "$1" 2>/dev/null | awk -v expr="$EXPREG" 'NR > 1 && $5 == "REG" && $9 ~ expr' | wc -l
  else
    lsof -u "$1" 2>/dev/null | awk 'NR > 1 && $5 == "REG"' | wc -l
  fi
}

get_process_oldest(){
  if [[ $(ps -u $1 -o pid,start_time --no-header --sort=start_time 2> /dev/null | wc -l) -eq 0  ]];then
    echo "NA"
  else 
    ps -u $1 -o pid,start_time --no-header --sort=start_time 2> /dev/null | awk 'NR==1 {print $1; exit}' 
  fi
}

# Procesamiento  de la línea de comandos.
while [[ $1 != "" ]]
do
  case "$1" in
    -h | --help )
      usage
      exit 0
    ;;
    -s | --sort ) 
      SORT=1
    ;;
    -f | --file )
      shift
      if [[ $1 == "" || $1 == -* ]]; then
        error_exit "Error: Falta la expresión regular."
      fi 
      EXPREG=$1
    ;;
    -u | --user )
      USERS=""
      LISTA_USERS=1
      if [[  $2 == "" || $2 == -* ]]; then
        error_exit "Error: Falta la lista de usuarios."
      fi
      while [[ $2 != "" && $2 != -* ]]
      do
        USERS="$USERS $2"
        shift
      done
    ;;
    -o | --offline )
      OFFLINE=1
    ;;
    -* )
      usage
      error_exit "Error: Opción no reconocida."
    ;;
    * ) 
      error_exit "Error: Argumento no conocido."
    
  esac
  shift
done


# Comprobación del estado de ejecución.
if ! lsof_es_instalado;then
  error_exit "Error: No está instalado lsof."
fi


if [[ $DIR != "" ]];then
  if ! directorio_existe $DIR;then
  error_exit "Error: El directorio de la variable de entorno $DIR no existe."
  fi
fi

for user in $USERS; do
  if ! user_existe $user;then
  error_exit "Error: El usuario $user no existe."
  fi
done 

# Lógica del programa.
SORT_CMD="sort  -k1,1"

if [[ $SORT == 1 ]];then
  SORT_CMD="sort -k4,4nr -k1,1"
fi

if [[ $OFFLINE == 1 ]]; then
  USERS_CONECTADOS=$(w | awk 'NR > 2 {print $1}' | sort -u)
  TODOS_LOS_USUARIOS=$(cut -d: -f1 /etc/passwd | sort -u)
  
  SOLO_DESCONECTADOS=$(comm -23 <(echo "$TODOS_LOS_USUARIOS") <(echo "$USERS_CONECTADOS"))
  
  if [[ $LISTA_USERS == 1 ]]; then
    USERS_FILTRADOS=""
    for user_i in $USERS; do
      if echo "$SOLO_DESCONECTADOS" | grep -q "^${user_i}$"; then
        USERS_FILTRADOS="$USERS_FILTRADOS $user_i"
      fi
    done
    USERS="$USERS_FILTRADOS"
  else
    USERS=$(echo "$SOLO_DESCONECTADOS" | tr '\n' ' ')
  fi
fi

printf "$FORMATO" USUARIO UID PID_ANTIGUO N_ARCHIVOS
for user in $USERS
do
  printf "$FORMATO" $user $(get_user_id $user) $(get_process_oldest $user) $(get_open_files $user)
done | $SORT_CMD

exit 0