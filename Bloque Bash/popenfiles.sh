#! /bin/bash

# Constantes:
PIDS=$(ps --no-header | awk '{print $1}' |  tr '\n' ',')
USA_DIRECTORIO=0
DIRECTORIO_INGRESADO=""
DIRECTORIO_ABSOLUTO=""
SORT=0
FORMATO_ALTERNATIVO=0


# Funciones:

error_exit(){
    echo "ERROR: ${1:-Error Desconocido.}"
    exit 1
}

usage(){
    echo "popenfiles [-h] [-d dir] [-f] [-sc]"
    exit 0
}

lsof_instalado(){
    type lsof > "/dev/null" 2> "/dev/null"
}

forma_alternativa(){
    ALTERNATIVA=""
    if [[ "$USA_DIRECTORIO" -eq 1 ]];then
        ALTERNATIVA=$(lsof  -p "$PIDS" -a +D"$DIRECTORIO_ABSOLUTO" -F n 2> "/dev/null")
    else
        ALTERNATIVA=$(lsof  -p "$PIDS" -F n 2> "/dev/null")
    fi
    
    for linea in $ALTERNATIVA;
    do
        LINEA_LIMPIA=""
        if echo "$linea" | grep -qE '^n/';then
            echo "$linea"
            LINEA_LIMPIA=$(echo "$linea" | sed "s-^n/-/-")
            get_mod_time "$LINEA_LIMPIA"
        else
            echo "$linea"
        fi
    done
}

get_mod_time(){
    if stat -c "%y" "$1" 2> "/dev/null";then
        return 0
    else
        return 1
    fi
}

# Procesamiento de los parámetros posicionales:
while [[ -n "$1" ]]
do
    case "$1" in
        -h )
            usage
        ;;
        -d ) 
            shift
            if [[ -z "$1" || "$1" == -* ]];then
                error_exit "Tiene que ingresar un directorio."
            fi
            USA_DIRECTORIO=1
            DIRECTORIO_INGRESADO=$1
        ;;
        -f )
            FORMATO_ALTERNATIVO=1
        ;;
        -sc )
            SORT=1
        ;;
        * ) 
            error_exit "Argumento $1 no válido."
        ;;
    esac
    shift
done



# Comprobación del estado de ejecución:
if ! lsof_instalado;then
    error_exit "El programa tiene que tener instalado el comando lsof."
fi


if [[ -n "$OPEN_FILES_COMM" ]];then
    PIDS_NUEVOS=$(ps -ax -o pid,comm --no-header | awk -v reg="$OPEN_FILES_COMM" '$2 ~ reg {print $1}' | tr '\n' ' ')
    for pid_n in $PIDS_NUEVOS;
    do
        PIDS="$PIDS,$pid_n"
    done
fi

if [[ "$USA_DIRECTORIO" -eq 1 ]];then
    if  ! [[ -d "$DIRECTORIO_INGRESADO" ]];then
        error_exit "No existe el directorio $DIRECTORIO_INGRESADO."
    else
        DIRECTORIO_ABSOLUTO=$(realpath "$DIRECTORIO_INGRESADO")
    fi
fi

# Lógica del programa:
if [[ "$SORT" -eq 1 ]];then
    if [[ "$USA_DIRECTORIO" -eq 1 ]];then
        if [[ "$FORMATO_ALTERNATIVO" -eq 1 ]];then
            forma_alternativa
        else
            lsof  -p "$PIDS" -a +D"$DIRECTORIO_ABSOLUTO" 2> "/dev/null" | sort -k1,1
        fi
    else
        if [[ "$FORMATO_ALTERNATIVO" -eq 1 ]];then
            forma_alternativa
        else
            lsof  -p "$PIDS" 2> "/dev/null" | sort -k1,1
        fi
    fi
else
    if [[ "$USA_DIRECTORIO" -eq 1 ]];then
        if [[ "$FORMATO_ALTERNATIVO" -eq 1 ]];then
            forma_alternativa
        else
            lsof  -p "$PIDS" -a +D"$DIRECTORIO_ABSOLUTO" 2> "/dev/null"
        fi
    else
        if [[ "$FORMATO_ALTERNATIVO" -eq 1 ]];then
            forma_alternativa
        else
            lsof  -p "$PIDS" 2> "/dev/null"
        fi
    fi
fi

exit 0