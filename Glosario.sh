#!/usr/bin/env bash
# =============================================================================
# glosario_bash.sh — Glosario de comandos de BASH
#
# Uso:
#   ./glosario_bash.sh              Lista todos los comandos con un resumen
#   ./glosario_bash.sh grep         Muestra la ficha completa de un comando
#   ./glosario_bash.sh grep sed     Varias fichas a la vez
#   ./glosario_bash.sh -a           Muestra todas las fichas
#   ./glosario_bash.sh -b texto     Busca un texto en todas las fichas
#   ./glosario_bash.sh -h           Ayuda
# =============================================================================

declare -A RESUMEN
declare -A FICHA

# Orden en el que se listan los comandos
ORDEN=(printf ls find sort cut grep head tail tr wc sed awk comm  ps w df du lsof)


# -----------------------------------------------------------------------------
# printf
# -----------------------------------------------------------------------------
RESUMEN[printf]="Imprime texto con formato (como el printf de C)."
IFS= read -r -d '' 'FICHA[printf]' <<'EOF'
SINTAXIS : printf [-v variable] FORMATO [argumentos...]
QUÉ HACE : Imprime los argumentos siguiendo la cadena de formato, que contiene
           texto literal, secuencias de escape y especificadores (%s, %d...).
ESPECIFICADORES :
  %s   Cadena de texto.
  %d   Entero decimal (%i es equivalente).
  %f   Número decimal; %.2f fija 2 decimales.
  %x   Hexadecimal (%X en mayúsculas); %o, octal.
  %c   Un carácter.
  %(fmt)T   Fecha y hora con formato strftime (bash 4.2+); -1 = ahora.
ANCHO Y ALINEACIÓN :
  %5d     Ancho mínimo 5, alineado a la derecha.
  %-10s   Ancho mínimo 10, alineado a la izquierda.
  %05d    Rellena con ceros a la izquierda.
  %.3s    Trunca la cadena a 3 caracteres.
ESCAPES  : \n salto de línea, \t tabulador, \\ barra invertida, \" comillas,
           \r retorno de carro, \e carácter de escape (colores ANSI).
EJEMPLOS :
  printf 'Hola, %s\n' "$USER"
  printf '%-10s %5d\n' ana 30 luis 7       # tabla alineada; el formato se reutiliza
  printf '%.2f\n' 3.14159                  # 3.14
  printf '%05d\n' 42                       # 00042
  printf '%x\n' 255                        # ff
  printf '%s\n' "${array[@]}"              # un elemento del array por línea
  printf -v ahora '%(%Y-%m-%d %H:%M)T' -1  # fecha actual en una variable
EOF



# -----------------------------------------------------------------------------
# ls
# -----------------------------------------------------------------------------
RESUMEN[ls]="Lista el contenido de directorios."
IFS= read -r -d '' 'FICHA[ls]' <<'EOF'
SINTAXIS : ls [opciones] [ruta...]
QUÉ HACE : Muestra los archivos y directorios de las rutas indicadas (por
           defecto, el directorio actual).
OPCIONES :
  -l   Formato largo: permisos, enlaces, propietario, grupo, tamaño y fecha.
  -a   Incluye archivos ocultos (también . y ..).
  -A   Incluye ocultos, pero sin . ni ..
  -h   Tamaños legibles (K, M, G); se usa junto a -l.
  -t   Ordena por fecha de modificación (más reciente primero).
  -S   Ordena por tamaño (mayor primero).
  -r   Invierte el orden.
  -R   Recursivo: entra en los subdirectorios.
EJEMPLOS :
  ls -lah
  ls -ltr                  # los más recientes al final
  ls -d */                 # solo los subdirectorios
EOF

# -----------------------------------------------------------------------------
# find
# -----------------------------------------------------------------------------
RESUMEN[find]="Busca archivos recorriendo un árbol de directorios según criterios."
IFS= read -r -d '' 'FICHA[find]' <<'EOF'
SINTAXIS : find [ruta...] [expresión]
QUÉ HACE : Recorre recursivamente las rutas y evalúa la expresión sobre cada
           archivo, imprimiendo los que la cumplen.
DETALLE  : Las condiciones se combinan con AND implícito; se pueden usar -o
           (OR), ! (NOT) y paréntesis escapados \( \). Las opciones que
           limitan la profundidad (-maxdepth) deben ir antes que los tests.
           Busca en el sistema de archivos real, no en una base de datos.
OPCIONES (tests y acciones):
  -name PATRÓN     Por nombre (usar comillas: '*.txt'). -iname ignora mayúsculas.
  -type f|d|l      Tipo: archivo, directorio, enlace simbólico.
  -size +10M       Por tamaño (+mayor que, -menor que; k, M, G).
  -mtime -7        Modificado hace menos de 7 días (+7 = hace más de 7).
  -mmin -30        Igual, pero en minutos.
  -user / -group   Por propietario o grupo.
  -perm 644        Por permisos (-perm -u+x = al menos esos bits).
  -empty           Archivos o directorios vacíos.
  -maxdepth N      Profundidad máxima de búsqueda (-mindepth N, la mínima).
  -exec CMD {} \;  Ejecuta CMD por cada resultado ({} es el archivo).
  -exec CMD {} +   Agrupa muchos resultados en una sola ejecución (más rápido).
  -delete          Borra los resultados (ojo: pruébalo antes sin -delete).
EJEMPLOS :
  find . -name '*.log' -mtime +30
  find /var -type f -size +100M
  find . -type f -name '*.tmp' -delete
  find . -type f -exec grep -l "TODO" {} +
  find . -name '*.txt' -print0 | xargs -0 wc -l
EOF



# -----------------------------------------------------------------------------
# sort
# -----------------------------------------------------------------------------
RESUMEN[sort]="Ordena las líneas de texto."
IFS= read -r -d '' 'FICHA[sort]' <<'EOF'
SINTAXIS : sort [opciones] [archivo...]
QUÉ HACE : Ordena las líneas de los archivos (o de la entrada estándar) y las
           escribe en la salida.
DETALLE  : Por defecto ordena alfabéticamente según la configuración regional
           (LC_ALL), por lo que "10" va antes que "2". Para un orden de bytes
           predecible y más rápido: LC_ALL=C sort. Es imprescindible antes de
           `uniq` y `comm`.
OPCIONES :
  -n   Orden numérico.
  -h   Orden numérico "humano" (1K, 2M, 3G).
  -r   Orden inverso.
  -u   Elimina duplicados (deja una línea por cada clave igual).
  -f   Ignora mayúsculas y minúsculas.
  -k N[,M]   Ordena por el campo N (hasta M). Se puede añadir tipo: -k2,2n.
EJEMPLOS :
  sort nombres.txt
  sort -t: -k3,3n /etc/passwd          # por UID
  du -sh * | sort -rh | head
  sort -u lista.txt
EOF



# -----------------------------------------------------------------------------
# cut
# -----------------------------------------------------------------------------
RESUMEN[cut]="Extrae columnas o campos de cada línea."
IFS= read -r -d '' 'FICHA[cut]' <<'EOF'
SINTAXIS : cut -f LISTA [-d DELIM] [archivo...]   |   cut -c LISTA [archivo...]
QUÉ HACE : Corta y muestra partes de cada línea, por campos, caracteres o bytes.
DETALLE  : El delimitador por defecto es el tabulador y solo puede ser un único
           carácter (para separadores múltiples, como varios espacios, es
           mejor `awk`). Las listas admiten rangos: 1,3  2-4  3-  -2.
           Mantiene el orden original de los campos (cut -f3,1 sale como 1,3).
OPCIONES :
  -d C           Delimitador de campos.
  -f LISTA       Selecciona campos.
  --complement   Muestra todo excepto lo seleccionado.
  -s             Ignora las líneas que no contienen el delimitador.
EJEMPLOS :
  cut -d: -f1 /etc/passwd              # nombres de usuario
  cut -d, -f2,4 datos.csv
  cut -c1-10 archivo.txt
  echo "a:b:c" | cut -d: -f2-
EOF

# -----------------------------------------------------------------------------
# grep
# -----------------------------------------------------------------------------
RESUMEN[grep]="Busca líneas que coinciden con un patrón."
IFS= read -r -d '' 'FICHA[grep]' <<'EOF'
SINTAXIS : grep [opciones] PATRÓN [archivo...]
QUÉ HACE : Imprime las líneas que contienen una coincidencia con el patrón
           (expresión regular).
DETALLE  : Por defecto usa expresiones regulares básicas; con -E, extendidas
           (+ ? | () sin escapar); con -F, texto literal. Devuelve 0 si
           encuentra coincidencias, 1 si no y 2 si hay error, lo que permite
           usarlo en condiciones: if grep -q patrón archivo; then ...
           Pon el patrón entre comillas para que la shell no lo expanda.
OPCIONES :
  -i   Ignora mayúsculas y minúsculas.
  -v   Invierte: muestra las líneas que NO coinciden.
  -n   Muestra el número de línea.
  -c   Cuenta las líneas que coinciden en lugar de mostrarlas.
  -r, -R   Busca recursivamente en directorios.
  -w   Coincide con palabras completas.
  -x   Coincide con la línea entera.
  -o   Muestra solo la parte que coincide.
  -E   Expresiones regulares extendidas.
EJEMPLOS :
  grep -rn "TODO" src/
  grep -E "error|fallo" app.log
  grep -v '^#' config.conf | grep -v '^$'    # sin comentarios ni vacías
  ps aux | grep -i nginx
EOF

# -----------------------------------------------------------------------------
# head
# -----------------------------------------------------------------------------
RESUMEN[head]="Muestra el principio de un archivo."
IFS= read -r -d '' 'FICHA[head]' <<'EOF'
SINTAXIS : head [opciones] [archivo...]
QUÉ HACE : Muestra las primeras 10 líneas de cada archivo (o de la entrada).
OPCIONES :
  -n N    Las primeras N líneas (-n -N: todas menos las últimas N).
EJEMPLOS :
  head -n 5 datos.csv
  head -n -1 archivo.txt        # todo menos la última línea
  ls -t | head -n 3
EOF

# -----------------------------------------------------------------------------
# tail
# -----------------------------------------------------------------------------
RESUMEN[tail]="Muestra el final de un archivo y puede seguir su crecimiento."
IFS= read -r -d '' 'FICHA[tail]' <<'EOF'
SINTAXIS : tail [opciones] [archivo...]
QUÉ HACE : Muestra las últimas 10 líneas de cada archivo (o de la entrada).
OPCIONES :
  -n N     Las últimas N líneas (-n +N: desde la línea N hasta el final).
EJEMPLOS :
  tail -n 20 /var/log/syslog
  tail -f /var/log/nginx/access.log
  tail -n +2 datos.csv           # omite la cabecera del CSV
EOF

# -----------------------------------------------------------------------------
# tr
# -----------------------------------------------------------------------------
RESUMEN[tr]="Traduce, comprime o borra caracteres de la entrada estándar."
IFS= read -r -d '' 'FICHA[tr]' <<'EOF'
SINTAXIS : tr [opciones] CONJUNTO1 [CONJUNTO2]
QUÉ HACE : Sustituye cada carácter de CONJUNTO1 por el correspondiente de
           CONJUNTO2, o lo borra o comprime según la opción.
DETALLE  : Solo lee de la entrada estándar (no acepta archivos como argumento),
           por lo que se usa con tuberías o redirecciones: tr ... < archivo.
           Trabaja con caracteres sueltos, no con cadenas: para sustituir
           palabras hay que usar `sed`.
           Admite rangos (a-z) y clases: [:upper:] [:lower:] [:digit:]
           [:alpha:] [:alnum:] [:space:] [:punct:].
OPCIONES :
  -d   Borra los caracteres de CONJUNTO1.
  -s   Comprime las repeticiones consecutivas en un solo carácter.
EJEMPLOS :
  echo "Hola" | tr 'a-z' 'A-Z'
  tr '[:lower:]' '[:upper:]' < texto.txt
  tr -d '\r' < windows.txt > unix.txt       # quita retornos de carro CRLF
  tr -s ' ' < texto.txt                     # espacios múltiples a uno solo
  tr -cd '[:digit:]\n' < datos.txt          # conserva solo los dígitos
EOF

# -----------------------------------------------------------------------------
# wc
# -----------------------------------------------------------------------------
RESUMEN[wc]="Cuenta líneas, palabras y bytes."
IFS= read -r -d '' 'FICHA[wc]' <<'EOF'
SINTAXIS : wc [opciones] [archivo...]
QUÉ HACE : Cuenta líneas, palabras y bytes (en ese orden si no se pasa ninguna
           opción).
OPCIONES :
  -l   Líneas.
  -w   Palabras.
  -c   Bytes.
EJEMPLOS :
  wc -l /etc/passwd
  ls | wc -l                 # número de elementos de un directorio
  wc -w ensayo.txt
EOF

# -----------------------------------------------------------------------------
# sed
# -----------------------------------------------------------------------------
RESUMEN[sed]="Editor de flujo: buscar, reemplazar o borrar texto línea a línea."
IFS= read -r -d '' 'FICHA[sed]' <<'EOF'
SINTAXIS : sed [opciones] 'script' [archivo...]
           comando | sed [opciones] 'script'
QUÉ HACE : Lee el texto entrante, aplica comandos simples de transformación 
           (como sustituir palabras o borrar líneas) y escupe el resultado. 
           Por defecto no modifica el archivo original, solo la salida de texto.

OPCIONES :
  -i        Edita el archivo original directamente (in-place). ¡Peligroso, usar con cuidado!
  -E        Activa las expresiones regulares extendidas (para usar +, ?, |).

COMANDOS BÁSICOS DENTRO DE SED :
  s/patrón/reemplazo/g   Sustituye 'patrón' por 'reemplazo'. 
                         (La 'g' al final significa "global": cambia TODAS las 
                         coincidencias en la línea, no solo la primera).
  d                      Borra la línea. (Ej: '1d' borra la línea 1).

EJEMPLOS : Sustituciones básicas
  sed 's/rojo/azul/g' texto.txt              # Cambia "rojo" por "azul" en todo el texto
  sed -i 's/localhost/127.0.0.1/g' conf.txt  # Modifica el archivo 'conf.txt' guardando los cambios.
EOF

# -----------------------------------------------------------------------------
# ps
# -----------------------------------------------------------------------------
RESUMEN[ps]="Muestra una instantánea de los procesos en ejecución."
IFS= read -r -d '' 'FICHA[ps]' <<'EOF'
SINTAXIS : ps [opciones]
QUÉ HACE : Lista los procesos del sistema con información como PID, usuario,
           uso de CPU y memoria, estado y comando.
DETALLE  : Sin opciones solo muestra los procesos de la terminal actual. 
           Al filtrar con grep, el propio grep aparece en la lista; el truco
           `grep [n]ginx` o usar `pgrep` lo evita.
OPCIONES (estilo POSIX, con guion):
  -A / -e      Lista todos los procesos del sistema.
  -j           Formato con información de la sesión y del grupo de procesos
               (PID, PGID, SID, TTY...).
  -p PID       Muestra solo el proceso con ese identificador (PID).
  -u USUARIO   Muestra solo los procesos de ese usuario.
  -f           Formato completo (UID, PPID, comando con argumentos).
  -C NOMBRE    Procesos con ese nombre de comando.
  -o CAMPOS    Elige, con una lista de campos separados por comas, la
               información que se quiere ver de cada proceso:
               ps -o user,pid,ppid,cmd (también vale ps -ouser,pid,ppid,cmd).
  --no-headers Omite la fila de encabezado donde se indica el contenido de cada
               columna. Útil en scripts, p. ej. para contar procesos.
  --sort=CAMPO Ordena: --sort=-%mem (de mayor a menor uso de memoria).
EJEMPLOS :
  ps a                                  # procesos de todos los usuarios con terminal
  ps x                                  # incluye los que no tienen terminal
  ps ax                                 # todos los procesos de todas las terminales
  ps -A                                 # todos los procesos del sistema
  ps -j                                 # con sesión y grupo de procesos
  ps -p 1287                            # solo el proceso con PID 1287
  ps -u yo                              # solo los procesos del usuario "yo"
  ps u                                  # formato orientado al usuario
  ps aux | less
  ps auxf                               # jerarquía de procesos en ASCII
  ps -ouser,pid,ppid,cmd                # columnas elegidas
  ps -A --no-headers | wc -l            # número de procesos del sistema
  ps -L -p 1234                         # hilos de un proceso
  ps aux --sort=-%mem | head
EOF

# -----------------------------------------------------------------------------
# df
# -----------------------------------------------------------------------------
RESUMEN[df]="Muestra el espacio libre y usado de los sistemas de archivos."
IFS= read -r -d '' 'FICHA[df]' <<'EOF'
SINTAXIS : df [opciones] [archivo|directorio...]
QUÉ HACE : Informa, por cada sistema de archivos montado, de su tamaño, espacio
           usado y disponible, el porcentaje de uso y el punto de montaje.
DETALLE  : Trabaja a nivel de sistema de archivos. Para saber cuánto ocupa un
           directorio concreto se usa `du`. Si se le pasa una ruta, muestra el
           sistema de archivos que la contiene (df -h .). Un disco puede estar
           "lleno" por falta de inodos aunque quede espacio: se comprueba
           con -i.
OPCIONES :
  -h   Tamaños legibles en potencias de 1024 (K, M, G).
  -H   Tamaños en potencias de 1000.
  -T   Muestra el tipo de sistema de archivos (ext4, xfs, tmpfs...).
  -i   Muestra el uso de inodos en vez del de bloques.
  -a   Incluye sistemas de archivos "ficticios" (con tamaño 0).
  -t TIPO   Muestra solo ese tipo de sistema de archivos.
  -x TIPO   Excluye ese tipo (p. ej. -x tmpfs).
  --total   Añade una fila con el total.
EJEMPLOS :
  df -h
  df -hT -x tmpfs -x devtmpfs
  df -h /home
  df -i /
EOF

# -----------------------------------------------------------------------------
# lsof
# -----------------------------------------------------------------------------
RESUMEN[lsof]="Lista los archivos abiertos y los procesos que los usan."
IFS= read -r -d '' 'FICHA[lsof]' <<'EOF'
SINTAXIS : lsof [opciones] [nombres]
QUÉ HACE : Muestra qué procesos tienen abiertos qué archivos. En Unix casi todo
           es un archivo: archivos regulares, directorios, tuberías, sockets
           de red y de dominio UNIX, dispositivos...
DETALLE  : Sin opciones lista todos los archivos abiertos de todos los procesos
           (se necesita root para verlos todos). Por defecto, las opciones
           se combinan con OR; con -a se combinan con AND.
           Muy útil para saber qué proceso ocupa un puerto, qué impide
           desmontar un dispositivo o qué archivo borrado sigue ocupando
           espacio en disco.
OPCIONES :
  -p PID        Archivos abiertos por ese proceso.
  -u USUARIO    Archivos abiertos por ese usuario.
  -c NOMBRE     Procesos cuyo comando empieza por NOMBRE.
  +D DIR        Todo lo abierto dentro de un directorio (recursivo).
  -a            Combina los filtros con AND.
  ARCHIVO       Procesos que tienen abierto ese archivo.
EJEMPLOS :
  sudo lsof -i :8080                 # quién usa el puerto 8080
  lsof -i TCP -sTCP:LISTEN -P -n     # puertos TCP en escucha
  lsof /var/log/syslog
  lsof -p 1234
EOF

# -----------------------------------------------------------------------------
# comm
# -----------------------------------------------------------------------------
RESUMEN[comm]="Compara dos archivos ordenados línea a línea."
IFS= read -r -d '' 'FICHA[comm]' <<'EOF'
SINTAXIS : comm [opciones] archivo1 archivo2
QUÉ HACE : Compara dos archivos y muestra tres columnas: líneas solo en el
           archivo 1, líneas solo en el archivo 2 y líneas comunes.
DETALLE  : Ambos archivos deben estar ordenados (con `sort`). Si no lo están,
           da resultados erróneos y avisa. La opción más práctica es suprimir
           columnas: -12 deja solo las comunes (intersección), -23 deja solo
           las del archivo 1 (diferencia). Con sustitución de procesos se
           puede ordenar al vuelo: comm <(sort a) <(sort b).
OPCIONES :
  -1   Suprime la columna 1 (solo en archivo1).
  -2   Suprime la columna 2 (solo en archivo2).
  -3   Suprime la columna 3 (comunes).
EJEMPLOS :
  comm -12 <(sort a.txt) <(sort b.txt)    # líneas en ambos
  comm -23 <(sort a.txt) <(sort b.txt)    # líneas solo en a.txt
  comm -3 a_ordenado.txt b_ordenado.txt   # lo que difiere
EOF

# -----------------------------------------------------------------------------
# awk
# -----------------------------------------------------------------------------
RESUMEN[awk]="Procesa texto por columnas: filtrado, agregación, patrones y cálculos."
IFS= read -r -d '' 'FICHA[awk]' <<'EOF'
SINTAXIS : awk [opciones] 'programa' [archivo...]
           comando | awk [opciones] 'programa'
QUÉ HACE : Lee la entrada línea a línea, dividiéndola en campos ($1, $2...). 
           Para cada línea evalúa reglas con la estructura "patrón { acción }". 
           Es la herramienta fundamental en scripts Bash para procesar salidas 
           de comandos como ps, df, lsof o archivos estructurados como /etc/passwd.

DETALLE  : - Sin patrón, la acción se aplica a todas las líneas.
           - Sin acción, imprime la línea completa ($0) si el patrón se cumple.
           - El patrón '1' se usa habitualmente para forzar el re-impresión de la línea.
           - IMPORTANTE: Pasa variables de la shell usando `-v var="$VALOR"`.
             No incluyas variables de la shell ($VAR) directamente dentro de las 
             comillas simples de awk.

OPCIONES :
  -F SEP        Define el separador de campos de entrada (ej. -F: para /etc/passwd).
                Por defecto considera cualquier secuencia de espacios o tabuladores.
  -v VAR=VAL    Pasa una variable de Bash a awk (disponible desde el bloque BEGIN).
  -f ARCHIVO    Carga las instrucciones de awk desde un archivo externo.

ESTRUCTURA DEL PROGRAMA :
  BEGIN { ... }    Se ejecuta UNA VEZ ANTES de leer cualquier línea (inicialización/cabeceras).
  patrón { ... }   Se ejecuta por cada línea que cumpla la condición.
  END { ... }      Se ejecuta UNA VEZ AL FINAL tras procesar toda la entrada (totales/resúmenes).

PATRONES MÁS COMUNES :
  NR > 1           Omite la primera línea (ideal para ignorar cabeceras de ps, df, lsof).
  $1 == "root"     Coincidencia exacta en un campo concreto.
  $3 >= 1000       Comparación numérica relacional.
  $NF ~ /reg$/     Expresión regular aplicada al último campo ($NF).
  !/patrón/        Líneas que NO coinciden con el patrón.
  NR==FNR          Verdadero solo al leer el primer archivo (para cruzar datos de 2 archivos).

VARIABLES INTEGRADAS IMPRESCINDIBLES :
  $0           La línea completa actual.
  $1, $2, ...  Columnas de la línea.
  $NF          Último campo (muy útil para rutas en lsof o comandos en ps).
  NF           Número total de campos en la línea actual.
  NR           Número de línea global acumulado.
  FNR          Número de línea dentro del archivo actual.
  OFS          Separador de campos de salida (por defecto espacio; cambia al usar comas en print).

EJEMPLOS : Selección de columnas y filtrado de cabeceras
  awk 'NR > 1 {print $1, $2}' datos.txt        # Salta la cabecera e imprime col 1 y 2
  awk -F: '{print $1, $3}' /etc/passwd         # Imprime usuario y UID desde /etc/passwd
  awk '{print $NF}' salida_lsof.txt            # Muestra solo la última columna (rutas)
  awk -v OFS='\t' '{print $1, $NF}' datos.txt  # Imprime columnas separadas por tabulador

EJEMPLOS : Filtrado con condiciones
  df -P | awk 'NR > 1 && $4 > 10000'           # Bloques disponibles > 10000 omitiendo cabecera
  ps aux | awk '$3 > 50.0 {print $2, $11}'     # PID y comando con uso de CPU > 50%
  lsof | awk -v reg="sh$" '$NF ~ reg'          # Procesa líneas cuya ruta ($NF) termine en 'sh'

EJEMPLOS : Acumuladores y Cálculos
  ps -u "$USER" -o rss | awk 'NR > 1 {s += $1} END {print s}'   # Suma total de memoria RSS
  lsof -u "$USER" | awk 'NR > 1 {c++} END {print c+0}'          # Cuenta líneas omitiendo cabecera
  awk '{s += $1} END {print (NR ? s/NR : 0)}' datos.txt         # Calcula la media sin división por 0

EJEMPLOS : Agrupar con Arrays Asociativos (Diccionarios)
  # Contar archivos abiertos por cada PID (agrupar por columna 2)
  lsof | awk 'NR > 1 {count[$2]++} END {for (pid in count) print pid, count[pid]}'

  # Sumar memoria consumida por cada usuario
  ps aux | awk 'NR > 1 {mem[$1] += $6} END {for (u in mem) print u, mem[u]}'

  # Sumar memoria por usuario y filtrar en END con for e if (>500MB)
  ps aux | awk 'NR > 1 {mem[$1] += $6} END {for (usr in mem) {if (mem[usr] > 500000) print usr, mem[usr]}}'

  # Eliminar líneas duplicadas sin desordenar el archivo
  awk '!seen[$0]++' archivo.txt

EJEMPLOS : Inyección de variables de Bash (-v)
  FILTRO=".*sh$"
  lsof | awk -v reg="$FILTRO" '$NF ~ reg {print $1, $NF}'

  MIN_KB=5000
  df -P | awk -v min="$MIN_KB" 'NR > 1 && $3 > min'
EOF

# -----------------------------------------------------------------------------
# w
# -----------------------------------------------------------------------------
RESUMEN[w]="Muestra quién está conectado y qué está haciendo, más la carga del sistema."
IFS= read -r -d '' 'FICHA[w]' <<'EOF'
SINTAXIS : w [opciones] [usuario]
QUÉ HACE : Lista los usuarios con sesión iniciada y el comando que ejecuta cada
           uno. La primera línea resume el sistema, igual que `uptime`: hora
           actual, tiempo encendido, número de usuarios y la carga media.
OPCIONES :
  -h   No muestra la cabecera.
  -s   Formato corto: omite LOGIN@, JCPU y PCPU.
EJEMPLOS :
  w
  w -h                  # sin la línea de cabecera
  w -s ana              # versión corta, solo el usuario ana
  w | head -1           # solo el resumen y la carga media
EOF

# -----------------------------------------------------------------------------
# id
# -----------------------------------------------------------------------------
RESUMEN[id]="Muestra el UID, el GID y los grupos de un usuario."
IFS= read -r -d '' 'FICHA[id]' <<'EOF'
SINTAXIS : id [opciones] [usuario]
QUÉ HACE : Muestra la identidad de un usuario (por defecto, el actual): su
           identificador de usuario (UID), su grupo principal (GID) y todos
           los grupos a los que pertenece.
DETALLE  : Salida típica: uid=1000(ana) gid=1000(ana) grupos=1000(ana),27(sudo).
OPCIONES :
  -u   Solo el UID.
  -g   Solo el GID del grupo principal.
  -G   Los identificadores de todos los grupos.
  -n   Muestra nombres en vez de números (con -u, -g o -G).
EJEMPLOS :
  id
  id root
  id -u                              # UID numérico
  id -un                             # nombre de usuario
  id -Gn                             # nombres de todos los grupos
  [ "$(id -u)" -eq 0 ] || echo "Hay que ejecutarlo como root" >&2
  id -nG ana | grep -qw docker && echo "ana está en docker"
EOF


# -----------------------------------------------------------------------------
# du
# -----------------------------------------------------------------------------
RESUMEN[du]="Calcula el espacio en disco que ocupan archivos y directorios."
IFS= read -r -d '' 'FICHA[du]' <<'EOF'
SINTAXIS : du [opciones] [ruta...]
QUÉ HACE : Recorre recursivamente los directorios indicados (por defecto, el
           actual) y muestra cuánto espacio en disco ocupa cada uno.
DETALLE  : Es el complemento de `df`: df informa del espacio de cada sistema de
           archivos, mientras que du mide lo que ocupa un conjunto concreto de
           archivos recorriéndolos. 
OPCIONES :
  -h          Tamaños legibles (K, M, G).
  -s          Solo el total de cada argumento (resumen).
  -a          Muestra también los archivos, no solo los directorios.
  -c          Añade una línea final con el total general.
  -d N        Profundidad máxima (--max-depth=N): du -h -d 1.
  -k / -m     Tamaños en KiB / MiB.
  -b          Tamaño aparente en bytes.
  --apparent-size   Tamaño de los datos en lugar del espacio en disco.
  --exclude=PATRÓN  Ignora los archivos que casen con el patrón.
  -S          No incluye en cada directorio el tamaño de sus subdirectorios.
  --time      Muestra la fecha de la última modificación.
EJEMPLOS :
  du -sh /var/log
  du -h -d 1 /home | sort -rh              # qué subdirectorios ocupan más
  du -ah . | sort -rh | head -10           # los 10 elementos más grandes
  du -sh --exclude='*.log' proyecto/
  du -shc *.iso                            # tamaño de cada ISO y el total
  du -xh -d 1 / 2>/dev/null | sort -rh | head
EOF

# =============================================================================
# Funciones de presentación
# =============================================================================
if [[ -t 1 ]]; then
    NEGRITA=$'\e[1m'; VERDE=$'\e[32m'; CIAN=$'\e[36m'; RESET=$'\e[0m'
else
    NEGRITA=""; VERDE=""; CIAN=""; RESET=""
fi

ayuda() {
    cat <<EOF
Uso: ${0##*/} [opción | comando...]

  (sin argumentos)   Lista todos los comandos con un resumen
  COMANDO...         Muestra la ficha completa de uno o varios comandos
  -a                 Muestra todas las fichas
  -b TEXTO           Busca TEXTO (sin distinguir mayúsculas) en las fichas
  -h                 Esta ayuda
EOF
}

listar() {
    printf '%sGLOSARIO DE COMANDOS DE BASH%s\n\n' "$NEGRITA" "$RESET"
    local c
    for c in "${ORDEN[@]}"; do
        printf '  %s%-7s%s %s\n' "$VERDE" "$c" "$RESET" "${RESUMEN[$c]}"
    done
    printf '\nUsa "%s COMANDO" para ver la ficha completa.\n' "${0##*/}"
}

ficha() {
    local c=$1
    if [[ -z ${FICHA[$c]:-} ]]; then
        printf 'No hay ficha para "%s".\n' "$c" >&2
        return 1
    fi
    printf '%s%s== %s ==%s  %s\n\n' "$NEGRITA" "$CIAN" "$c" "$RESET" "${RESUMEN[$c]}"
    printf '%s\n\n' "${FICHA[$c]}"
}

buscar() {
    local texto=$1 c encontrado=1
    for c in "${ORDEN[@]}"; do
        if grep -qiF -- "$texto" <<<"${RESUMEN[$c]}"$'\n'"${FICHA[$c]}"; then
            printf '  %s%-7s%s %s\n' "$VERDE" "$c" "$RESET" "${RESUMEN[$c]}"
            encontrado=0
        fi
    done
    ((encontrado)) && printf 'Sin resultados para "%s".\n' "$texto" >&2
    return "$encontrado"
}

# =============================================================================
# Programa principal
# =============================================================================
main() {
    case ${1:-} in
        "")       listar ;;
        -h|--help) ayuda ;;
        -a)       for c in "${ORDEN[@]}"; do ficha "$c"; done ;;
        -b)       [[ -n ${2:-} ]] || { ayuda; return 1; }; buscar "$2" ;;
        *)        local estado=0 c
                  for c in "$@"; do ficha "$c" || estado=1; done
                  return "$estado" ;;
    esac
}

main "$@"