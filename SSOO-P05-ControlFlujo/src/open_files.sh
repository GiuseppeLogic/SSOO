#! /bin/bash

# Constantes:
FORMATO="%-18s %10s %10s %10s\n"
USERS=$(w | awk 'NR>2 {print $1}' | sort -u | tr '\n' ' ')
SORT=0
FILE_FOLDER=${OPEN_FILES_FOLDER:-""}
EXPRESION_REGULAR=""
USA_EXPRESION_REGULAR=0
NO_CONECTADOS=0
USA_USUARIOS=0

# Funciones:
error_exit(){
  echo "ERROR: ${1:- Error Desconocido.}" >&2
  exit 1
}

usage(){
  echo "Uso: open_files [-h | --help] [-f regexp] [-o] [--offline]  [-u usuario ...]  [-s ] [–sort]"
}

lsof_instalado(){
  type lsof > "/dev/null" 2> "/dev/null"
}

obtener_id(){
  id -u "$1" 2> "/dev/null"
}

usuario_existe(){
  id  -u "$1" > "/dev/null" 2> "/dev/null"
}

obtener_pid_antiguo(){
  ps -u "$1" --no-header -o pid --sort=start_time | awk  'BEGIN{pid="NA"} NR==1{pid=$1} END {print pid}' 
}

archivos_abiertos(){
  if [[ -n "$FILE_FOLDER" && "$USA_EXPRESION_REGULAR" -eq 1 ]];then
    lsof -u "$1" -a +D"$FILE_FOLDER" | awk -v reg="$EXPRESION_REGULAR" 'NR>1 && $5=="REG" && $NF ~ reg  {suma += 1} END {print suma+0}'
  elif [[ "$USA_EXPRESION_REGULAR" -eq 1 ]];then
    lsof -u "$1" | awk -v reg="$EXPRESION_REGULAR" 'NR>1 && $5=="REG" && $NF ~ reg  {suma += 1} END {print suma+0}'
  elif [[ -n "$FILE_FOLDER" ]];then
    lsof -u "$1" -a +D"$FILE_FOLDER" | awk 'NR>1 && $5=="REG" {suma += 1} END {print suma+0}'
  else
    lsof -u "$1" | awk 'NR>1 && $5=="REG" {suma += 1} END {print suma+0}'
  fi
}

# Procesamiento del flujo de datos:

while [[ -n "$1" ]];
do
  case "$1" in
    -h | --help )
      usage
      exit 0
    ;;
    -f )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Debe ingresar la expresión regular."
      fi
      USA_EXPRESION_REGULAR=1
      EXPRESION_REGULAR="$1"
    ;;
    -s | --sort )
      SORT=1
    ;;
    -o | --offline )
      NO_CONECTADOS=1
    ;;
    -u )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Debe ingresar un usuario."
      fi
      USERS=""
      USA_USUARIOS=1
      while [[ -n "$1" && "$1" != -* ]]
      do
        USERS="$USERS $1"
        shift
      done
      continue
    ;;
    * )
      error_exit "Argumento $1 no válido."
    ;;
  esac
  shift
done

# Comprobación del estado de ejecución:

if ! lsof_instalado;then
  error_exit "Tiene que estar instalado el programa lsof."
fi

if [[ "$USA_USUARIOS" -eq 1 ]];then
  for usuario in $USERS
  do
    if  ! usuario_existe "$usuario";then
      error_exit "El usuario $usuario no existe."
    fi
  done
fi

if [[ -n "$FILE_FOLDER" ]];then
  if [[ ! -d "$FILE_FOLDER" ]];then
    error_exit "La ruta $FILE_FOLDER no es un directorio."
  fi
fi

# Lógica del programa:
SORT_CMD="sort -k1,1"

if [[ "$SORT" -eq 1 ]];then
  SORT_CMD="sort -k4,4nr"
fi

if [[ "$NO_CONECTADOS" -eq 1 ]];then
  TODOS_USUARIOS=$(cat /etc/passwd | awk -F ':' '{print $1}' | sort -u)
  USUARIOS_ACTIVOS=$(w | awk 'NR>2 {print $1}' | sort -u)

  USUARIOS_DESCONECTADOS=$(comm -23 <(echo "$TODOS_USUARIOS") <(echo "$USUARIOS_ACTIVOS"))

  if [[ "$USA_USUARIOS" -eq 1 ]];then
    USER_FILTRO=""
    for usuario in $USERS;
    do
      if echo "$USUARIOS_DESCONECTADOS" | grep -q "^${usuario}\$";then
        USER_FILTRO="$USER_FILTRO $usuario"
      fi
    done
    USERS="$USER_FILTRO"
  else
    USERS=$(echo "$USUARIOS_DESCONECTADOS" | tr '\n' ' ')
  fi
fi

printf "$FORMATO" USUARIO UID  PID_ANTIGUO  N_ARCHIVOS 
for user in $USERS
do
  printf "$FORMATO" "$user" $(obtener_id "$user") $(obtener_pid_antiguo "$user") $(archivos_abiertos "$user")
done | $SORT_CMD

exit 0