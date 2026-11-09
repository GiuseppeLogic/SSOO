#! /bin/bash

# Cosntantes:
LISTA_DIRECTORIOS=$(echo "$PATH" | tr ':' ' ')
USA_DIRECTORIO=0
DIRECTORIO_INGRESADO=""
USA_USUARIO=0
USUARIO=""
USA_PROCESOS_USUARIO=0

# Funciones:

error_exit(){
  echo "ERROR: ${1:-Error Desconocido.}"
  exit 1
}

usage(){
  echo "Uso:"
}

lsof_instalado(){
  type lsof > "/dev/null" 2> "/dev/null"
}

usuario_existe(){
  id "$1" > "/dev/null" 2> "/dev/null"
}

# Procesamiento de los parámetros posicionales:

if [[ -n "$1" ]];then
  while [[ -n "$1" ]];
  do
    case "$1" in 
      -h )
        usage
        exit 0
      ;;
      -d )
        shift
        if [[ -z "$1" || "$1" == -* ]];then
          error_exit "Tienes que ingresar un directorio."
        fi
        USA_DIRECTORIO=1
        DIRECTORIO_INGRESADO="$1"
        LISTA_DIRECTORIOS="$DIRECTORIO_INGRESADO"
      ;;
      -u )
        shift
        if [[  -z "$1" || "$1" == -* ]];then
          error_exit "Tienes que ingresar un usuario."
        fi
        USA_USUARIO=1
        USUARIO="$1"
      ;;
      -w )
        USA_PROCESOS_USUARIO=1
        PIDS=$(ps -u "$USER" --no-header | awk '{print $1}' |  tr '\n' ' ')
        LISTA_DIRECTORIOS=""
        for pid in $PIDS;
        do
          DIRECTORIO=$(pwdx "$pid" 2> "/dev/null" | awk '{print $NF}')
          if ! [[ -d "$DIRECTORIO" ]];then
            echo "El pid $pid no devuelve una ruta existente."
            continue
          fi
          LISTA_DIRECTORIOS="$LISTA_DIRECTORIOS $DIRECTORIO"
        done
      ;;
      * ) 
        error_exit "El argumento $1 no es válido."
      ;;
    esac
    shift
  done
else
  LISTA_DIRECTORIOS="$LISTA_DIRECTORIOS $HOME"
fi


# Comprobación del estado de ejecución:

if ! lsof_instalado;then
  error_exit "No está instalado lsof."
fi

if [[ "$USA_PROCESOS_USUARIO" -eq  1 && "$USA_USUARIO"  -eq 1 ]] || [[ "$USA_PROCESOS_USUARIO" -eq  1 && "$USA_DIRECTORIO"  -eq 1 ]];then
  error_exit "No puedes compatibilizar la opción -w junto con alguna de las opciones -d o -u."
fi

if [[ -n "$OPEN_FILES_FOLDER" && -d "$OPEN_FILES_FOLDER" ]];then
  if [[ "$USA_DIRECTORIO" -eq 1 ]];then
    LISTA_DIRECTORIOS="$OPEN_FILES_FOLDER $DIRECTORIO_INGRESADO"
  else
    LISTA_DIRECTORIOS="$OPEN_FILES_FOLDER"
  fi
else
  if [[ -n "$OPEN_FILES_FOLDER" ]];then
    error_exit "No existe o no es un directorio la ruta  $OPEN_FILES_FOLDER."
  fi
fi

if [[ "$USA_USUARIO" -eq 1 ]];then
  if ! usuario_existe "$USUARIO";then
    error_exit "El usuario $USUARIO no existe."
  fi
fi

# Lógica del programa:

for directorio in $LISTA_DIRECTORIOS
do
  if [[ "$USA_USUARIO" -eq 1 ]];then
    lsof +D"$directorio" -a -u "$USUARIO" 2> "/dev/null" | awk 'NR>1 {print $0}'
  else
    lsof +D"$directorio" 2> "/dev/null" | awk 'NR>1 {print $0}'
  fi
done