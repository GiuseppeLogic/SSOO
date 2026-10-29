#! /bin/bash

# Constantes:
FORMATO="%-10s %10s\n"
USERS=$(cat /etc/passwd | awk -F ":" '{print $1}' | tr '\n'  ' ')
SORT=0
FILTRO=""
FILTRO_INGRESADO=0
FILTRO_VARIABLE=0
LISTA_USERS=0
# Funciones:
error_exit(){
  echo "ERROR: $1" >&2
  exit 1
}

lsof_instalado(){
  type lsof > "/dev/null" 2> "/dev/null"
}

user_existe(){
  id "$1" > /dev/null 2> /dev/null
}

# Procesamiento de parámetros posicionales:

while [[ -n "$1" ]]
do
  case "$1" in
    -f )
       shift
       if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tienes que ingresar una expresión regular."
      fi
      FILTRO_INGRESADO=1
      FILTRO="$1"
    ;;
    -r )
      SORT=1
    ;;
    -e )
      if [[ -z "$OPEN_FILES_REG" ]];then
        error_exit "La variable de entorno no puede estar vacía."
      fi
      FILTRO_VARIABLE=1
      FILTRO="$OPEN_FILES_REG"
    ;;
    -u )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Tiene que ingresar como mínimo un usuario."
      fi
      LISTA_USERS=1
      USERS=""
      while [[ -n "$1" && "$1" != -* ]]
      do
        USERS="$USERS $1"
        shift
      done
      continue
    ;;
    * )
      error_exit "Has ingresado un argumento inválido."
    ;;
  esac
  shift
done

# Comprobación del estado de ejecución:
if ! lsof_instalado;then
  error_exit "Se necesita tener instalado el programa lsof."
fi 

if [[ "$FILTRO_INGRESADO" == 1 && "$FILTRO_VARIABLE" == 1 ]];then
  error_exit "La opción -e y -f son incompatibles."
fi

if [[ "$LISTA_USERS" != 0 ]];then
  for user in $USERS
  do
    if ! user_existe "$user";then
      error_exit "El usuario $user no existe."
    fi
  done
fi

# Lógica del programa:
SORT_CMD="sort -k2,2nr"

if [[ "$SORT" == 1 ]];then
  SORT_CMD="sort -k2,2n"
fi

printf "$FORMATO" USUARIO N_ARCHIVOS
for user in $USERS
do
  if [[ $(lsof -u "$user" | wc -l) -gt 0 ]];then
    if [[ -n "$FILTRO" ]];then
      printf "$FORMATO" "$user" $(lsof -u "$user" 2> /dev/null | awk -v reg="$FILTRO" 'NR > 1 && $NF ~ reg "$" {suma++} END {print (suma != 0) ? suma : 0}')
    else
      printf "$FORMATO" "$user" $(lsof -u "$user" 2> /dev/null | awk 'NR>1' | wc -l)
    fi
  fi
done |  $SORT_CMD
