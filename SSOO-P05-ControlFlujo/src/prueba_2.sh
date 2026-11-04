#! /bin/bash

# Constantes:
FORMATO="%-20s %10s\n"
USUARIOS=$(cat /etc/passwd | awk -F ':' '{print $1}' | tr '\n' ' ')
SORT=0
EXPRESION_REGULAR=""
USAR_VARIABLE_ENTORNO=0
USAR_EXPRESION_REGULAR=0
USAR_USUARIOS=0

# Funciones:
error_exit(){
  echo "ERROR: ${1:-Error Desconocido.}" >&2
  exit 1
}

lsof_instalado(){
  type lsof > "/dev/null" 2> "/dev/null"
}

get_open_files(){
  if [[ -n "$EXPRESION_REGULAR" ]];then
    lsof -u "$1" 2> "/dev/null"  | awk -v reg="$EXPRESION_REGULAR" 'NR>1 && $NF ~ reg {suma += 1} END {print (suma) ? suma : 0}'
  else
    lsof -u "$1" 2> "/dev/null" | awk 'NR>1' | wc -l
  fi

}

usuario_existe(){
  id "$1" > "/dev/null" 2> "/dev/null"
}

# Procesamiento de los parámetros posicionales:

while [[ -n "$1" ]]
do
  case "$1" in
    -r )
      SORT=1
    ;;
    -f )
      shift
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Se tiene que ingresar una expresión regular válida."
      fi
      USAR_EXPRESION_REGULAR=1
      EXPRESION_REGULAR="$1$"
    ;;
    -u ) 
      shift 
      if [[ -z "$1" || "$1" == -* ]];then
        error_exit "Debes ingresar almenos un usuario."
      fi
      USUARIOS=""
      USAR_USUARIOS=1
      while [[ -n "$1" && "$1" != -* ]]
      do
        USUARIOS="$USUARIOS $1"
        shift
      done
      continue
    ;;
    -e )
      USAR_VARIABLE_ENTORNO=1
    ;;
    * )
      error_exit "Argumento no válido $1."
    ;;
  esac
  shift
done

# Comprobación del estado de ejecución del programa:
if ! lsof_instalado;then
  error_exit "Se debe instalar el programa lsof."
fi

if [[ "$USAR_VARIABLE_ENTORNO" -eq 1 && "$USAR_EXPRESION_REGULAR" -eq 1 ]];then
  error_exit "No se pueden usar simultaneamente ambas opciones."
fi

if [[ "$USAR_VARIABLE_ENTORNO" -eq 1 &&  -z "$OPEN_FILES_REG" ]];then
  error_exit "La variable de entorno OPEN_FILES_REG está vacía."
elif [[ "$USAR_VARIABLE_ENTORNO" -eq 1 ]];then
  EXPRESION_REGULAR="$OPEN_FILES_REG$"
fi

if [[ "$USAR_USUARIOS" -eq 1 ]];then
  for usuario in $USUARIOS
  do
    if ! usuario_existe "$usuario";then
      error_exit "No existe el usuario $usuario"
    fi
  done
fi

# Lógica del programa:
SORT_CMD="sort -k2,2nr"

if [[ "$SORT" -eq 1 ]];then
  SORT_CMD="sort -k2,2n"
fi

printf "$FORMATO" USUARIO N_ARCHIVOS
for usuario in $USUARIOS
do
  if [[ $(get_open_files "$usuario") -gt 0 ]];then
    printf "$FORMATO" "$usuario" $(get_open_files "$usuario")
  fi 
done
