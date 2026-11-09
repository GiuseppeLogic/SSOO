#! /bin/bash

# Constantes:
FORMATO="%-10s %10s\n"
OPEN_FILES_FOLDER=${OPEN_FILES_FOLDER:-"/"}
USERS=""
LISTA_USERS=0

# Funciones:
error_exit(){
  echo "ERROR: $1" >&2
  exit 1
}

lsof_instalado(){
  type lsof > /dev/null 2> /dev/null
}

directorio_existe(){
  if [[ ! -d "$1" ]];then
    error_exit "El directorio $OPEN_FILES_FOLDER no existe"
  fi
}

usuario_existe(){
  id "$1" > "/dev/null" 2> "/dev/null"
}

# Procesamiento de parámetros posicionales:
while [[ -n "$1" ]]
do
  case "$1" in
    -d )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar un directorio."
      fi
      OPEN_FILES_FOLDER="$1"
    ;;
    -u )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar al menos un usuario."
      fi
      LISTA_USERS=1
      while [[ -n "$1" && "$1" != -* ]]
      do
        USERS="$USERS $1"
        shift
      done
      continue
    ;;
    * )
      error_exit "No es un argumento válido."
    ;;
  esac
  shift
done

# Comprobación estado del programa:
if ! lsof_instalado;then
  error_exit "El programa lsof debe estar instalado."
fi

directorio_existe "$OPEN_FILES_FOLDER"

for user in $USERS
do
  if !usuario_existe $user;then
    error_exit "No existe el usuario $user."
  fi
done

# Lógica del programa.
SORT_CMD="sort -k2,2nr"

if [[ "$LISTA_USERS" == 0 ]];then
  PIDS=$(ps -u "$USER" --no-header -o pid | sort -u |  tr '\n' ' ' )
else
  for user in $USERS
  do
    PIDS_USER=$(ps -u "$user" --no-header -o pid | sort -u | tr '\n' ' ' )
    PIDS="$PIDS $PIDS_USER"
  done
fi

printf "$FORMATO" PID N_ARCHIVO
for pid in $PIDS
do  
  printf "$FORMATO" "$pid" $(lsof -p "$pid" -a +D"$OPEN_FILES_FOLDER" 2> /dev/null | awk 'NR>1' | wc -l)  
done | $SORT_CMD

