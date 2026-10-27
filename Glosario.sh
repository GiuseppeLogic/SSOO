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
ORDEN=(echo printf which cat type ls find less file cp ln mv rm mkdir chmod chgrp
       chown id sort uniq cut grep head tail tr wc sed awk comm diff ps w top
       kill pkill pgrep jobs bg fg df du lsof)

# -----------------------------------------------------------------------------
# echo
# -----------------------------------------------------------------------------
RESUMEN[echo]="Imprime sus argumentos por la salida estándar."
IFS= read -r -d '' 'FICHA[echo]' <<'EOF'
SINTAXIS : echo [opciones] [texto...]
QUÉ HACE : Escribe los argumentos separados por espacios y termina con un salto
           de línea. Es un comando interno (builtin) de bash.
DETALLE  : Sin comillas, bash expande variables y comodines antes de que echo
           los reciba. Para salida portable y con formato es mejor `printf`,
           porque el comportamiento de -e y -n varía entre shells.
OPCIONES :
  -n   No añade el salto de línea final.
  -e   Interpreta secuencias de escape (\n, \t, \\, \e para colores...).
  -E   No interpreta escapes (valor por defecto).
EJEMPLOS :
  echo "Hola $USER"
  echo -n "Sin salto"
  echo -e "Línea 1\nLínea 2"
  echo $?                  # código de salida del último comando
EOF

# -----------------------------------------------------------------------------
# printf
# -----------------------------------------------------------------------------
RESUMEN[printf]="Imprime texto con formato (como el printf de C)."
IFS= read -r -d '' 'FICHA[printf]' <<'EOF'
SINTAXIS : printf [-v variable] FORMATO [argumentos...]
QUÉ HACE : Imprime los argumentos siguiendo la cadena de formato, que contiene
           texto literal, secuencias de escape y especificadores (%s, %d...).
DETALLE  : No añade salto de línea al final: hay que poner \n. Es un builtin de
           bash y es más portable y predecible que `echo`, sobre todo si los
           datos pueden empezar por guion o contener barras invertidas.
           Si hay más argumentos que especificadores, el formato se reutiliza
           hasta consumirlos todos. Para imprimir datos arbitrarios es seguro
           usar printf '%s\n' "$dato" (nunca el dato como formato).
ESPECIFICADORES :
  %s   Cadena de texto.
  %d   Entero decimal (%i es equivalente).
  %f   Número decimal; %.2f fija 2 decimales.
  %x   Hexadecimal (%X en mayúsculas); %o, octal.
  %c   Un carácter.
  %b   Cadena interpretando los escapes que contenga el argumento.
  %q   Cadena escapada para poder reutilizarla como entrada de la shell.
  %%   Un símbolo % literal.
  %(fmt)T   Fecha y hora con formato strftime (bash 4.2+); -1 = ahora.
ANCHO Y ALINEACIÓN :
  %5d     Ancho mínimo 5, alineado a la derecha.
  %-10s   Ancho mínimo 10, alineado a la izquierda.
  %05d    Rellena con ceros a la izquierda.
  %.3s    Trunca la cadena a 3 caracteres.
ESCAPES  : \n salto de línea, \t tabulador, \\ barra invertida, \" comillas,
           \r retorno de carro, \e carácter de escape (colores ANSI).
OPCIONES :
  -v VAR   Guarda el resultado en la variable VAR en lugar de imprimirlo.
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
# which
# -----------------------------------------------------------------------------
RESUMEN[which]="Muestra la ruta del ejecutable que se lanzaría según el PATH."
IFS= read -r -d '' 'FICHA[which]' <<'EOF'
SINTAXIS : which [opciones] comando...
QUÉ HACE : Busca el comando en los directorios de $PATH y muestra la ruta del
           primer ejecutable que encuentra.
DETALLE  : Es un programa externo, no un builtin, así que no ve alias, funciones
           ni builtins de la shell. Para saber cómo interpreta bash un nombre
           es más fiable `type`. Devuelve código distinto de 0 si no lo halla.
OPCIONES :
  -a   Muestra todas las coincidencias en el PATH, no solo la primera.
EJEMPLOS :
  which python3
  which -a python3         # todas las versiones que hay en el PATH
EOF

# -----------------------------------------------------------------------------
# cat
# -----------------------------------------------------------------------------
RESUMEN[cat]="Concatena archivos y los muestra por la salida estándar."
IFS= read -r -d '' 'FICHA[cat]' <<'EOF'
SINTAXIS : cat [opciones] [archivo...]
QUÉ HACE : Lee los archivos en orden y escribe su contenido seguido. Sin
           argumentos (o con `-`) lee de la entrada estándar.
DETALLE  : Sirve tanto para ver archivos pequeños como para unir varios
           (cat a b > c) o crear uno desde la terminal con un here-document.
           `tac` hace lo mismo pero invirtiendo el orden de las líneas.
OPCIONES :
  -n   Numera todas las líneas.
  -b   Numera solo las líneas no vacías.
  -s   Comprime varias líneas vacías seguidas en una.
  -A   Muestra caracteres no imprimibles ($ fin de línea, ^I tabulador...).
  -E   Marca con $ el final de cada línea.
EJEMPLOS :
  cat /etc/os-release
  cat parte1.txt parte2.txt > completo.txt
  cat -A script.sh         # detecta tabuladores y fines de línea de Windows
  cat > notas.txt          # escribe y termina con Ctrl+D
EOF

# -----------------------------------------------------------------------------
# type
# -----------------------------------------------------------------------------
RESUMEN[type]="Indica cómo interpreta bash un nombre (alias, función, builtin, archivo)."
IFS= read -r -d '' 'FICHA[type]' <<'EOF'
SINTAXIS : type [opciones] nombre...
QUÉ HACE : Informa de qué se ejecutaría al escribir ese nombre: alias, palabra
           reservada (keyword), función, comando interno (builtin) o archivo.
DETALLE  : Es un builtin de bash y es más completo que `which`, porque conoce
           todo lo que la shell resuelve. Útil para saber por qué un comando se
           comporta de forma inesperada (por ejemplo, un alias que lo tapa).
OPCIONES :
  -t   Imprime solo el tipo: alias, keyword, function, builtin o file.
  -a   Muestra todas las definiciones que coinciden con el nombre.
  -p   Muestra la ruta solo si el nombre se resolvería como archivo.
EJEMPLOS :
  type cd                  # cd is a shell builtin
  type -a ls               # alias y ejecutable
  type -t if               # keyword
EOF

# -----------------------------------------------------------------------------
# ls
# -----------------------------------------------------------------------------
RESUMEN[ls]="Lista el contenido de directorios."
IFS= read -r -d '' 'FICHA[ls]' <<'EOF'
SINTAXIS : ls [opciones] [ruta...]
QUÉ HACE : Muestra los archivos y directorios de las rutas indicadas (por
           defecto, el directorio actual).
DETALLE  : Con -l la primera columna indica el tipo (- archivo, d directorio,
           l enlace simbólico) y los permisos rwx de propietario, grupo y
           otros. No muestra los archivos ocultos (que empiezan por punto)
           salvo con -a o -A.
OPCIONES :
  -l   Formato largo: permisos, enlaces, propietario, grupo, tamaño y fecha.
  -a   Incluye archivos ocultos (también . y ..).
  -A   Incluye ocultos, pero sin . ni ..
  -h   Tamaños legibles (K, M, G); se usa junto a -l.
  -t   Ordena por fecha de modificación (más reciente primero).
  -S   Ordena por tamaño (mayor primero).
  -r   Invierte el orden.
  -R   Recursivo: entra en los subdirectorios.
  -d   Muestra el directorio en sí, no su contenido.
  -i   Muestra el número de inodo.
  -1   Un elemento por línea.
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
  -print0          Separa por carácter nulo; se usa con `xargs -0`.
EJEMPLOS :
  find . -name '*.log' -mtime +30
  find /var -type f -size +100M
  find . -type f -name '*.tmp' -delete
  find . -type f -exec grep -l "TODO" {} +
  find . -name '*.txt' -print0 | xargs -0 wc -l
EOF

# -----------------------------------------------------------------------------
# less
# -----------------------------------------------------------------------------
RESUMEN[less]="Paginador interactivo para leer archivos o salidas largas."
IFS= read -r -d '' 'FICHA[less]' <<'EOF'
SINTAXIS : less [opciones] [archivo...]
QUÉ HACE : Muestra el contenido por pantallas permitiendo avanzar y retroceder.
           No carga el archivo entero, por lo que abre ficheros enormes al
           instante.
DETALLE  : Se usa muy a menudo al final de una tubería: comando | less.
OPCIONES :
  -N   Numera las líneas.
  -S   No parte las líneas largas (se desplaza en horizontal).
  -i   Búsquedas sin distinguir mayúsculas (si el patrón va en minúsculas).
  -R   Interpreta los colores ANSI (útil con `ls --color` o `grep --color`).
  +F   Arranca en modo seguimiento, como `tail -f` (Ctrl+C sale del modo).
TECLAS   :
  Espacio / b    Página siguiente / anterior
  j / k          Línea siguiente / anterior
  g / G          Principio / final del archivo
  /patrón        Busca hacia delante (?patrón hacia atrás); n / N siguiente / previa
  q              Salir
EJEMPLOS :
  less -N /etc/passwd
  journalctl | less +G
EOF

# -----------------------------------------------------------------------------
# file
# -----------------------------------------------------------------------------
RESUMEN[file]="Determina el tipo de un archivo analizando su contenido."
IFS= read -r -d '' 'FICHA[file]' <<'EOF'
SINTAXIS : file [opciones] archivo...
QUÉ HACE : Identifica el tipo de archivo (texto ASCII/UTF-8, ejecutable ELF,
           imagen, PDF, script...) mirando su contenido y sus "números
           mágicos", no su extensión.
DETALLE  : Es muy útil cuando un archivo no tiene extensión o esta engaña.
           También informa de la codificación y de si el texto usa fines de
           línea de Windows (CRLF).
OPCIONES :
  -i, --mime-type   Salida en formato MIME (con -i también la codificación).
  -b                Modo breve: omite el nombre del archivo en la salida.
  -L                Sigue los enlaces simbólicos.
  -f LISTA          Lee de un archivo la lista de nombres a analizar.
EJEMPLOS :
  file /bin/ls
  file -i documento.txt
  file --mime-type -b imagen.jpg
EOF

# -----------------------------------------------------------------------------
# cp
# -----------------------------------------------------------------------------
RESUMEN[cp]="Copia archivos y directorios."
IFS= read -r -d '' 'FICHA[cp]' <<'EOF'
SINTAXIS : cp [opciones] origen... destino
QUÉ HACE : Copia uno o varios archivos a un destino. Si hay varios orígenes, el
           destino debe ser un directorio.
DETALLE  : Sin -r no copia directorios. Sobrescribe el destino sin avisar,
           salvo con -i o -n. La copia es un archivo nuevo, con fecha y
           propietario propios, salvo que se use -p o -a.
OPCIONES :
  -r, -R   Recursivo: copia directorios y su contenido.
  -a       Archivo: recursivo conservando permisos, fechas, propietario y
           enlaces simbólicos (equivale a -dR --preserve=all).
  -p       Conserva permisos, propietario y fechas.
  -i       Pregunta antes de sobrescribir.
  -n       No sobrescribe archivos existentes.
  -u       Copia solo si el origen es más nuevo que el destino.
  -v       Muestra lo que va copiando.
  -t DIR   Indica el directorio destino al principio (útil con xargs).
EJEMPLOS :
  cp informe.txt informe.bak
  cp -a proyecto/ copia_proyecto/
  cp -iv *.jpg ~/Imágenes/
EOF

# -----------------------------------------------------------------------------
# ln
# -----------------------------------------------------------------------------
RESUMEN[ln]="Crea enlaces (duros o simbólicos) a archivos."
IFS= read -r -d '' 'FICHA[ln]' <<'EOF'
SINTAXIS : ln [opciones] destino nombre_del_enlace
QUÉ HACE : Crea un nuevo nombre para un archivo existente.
DETALLE  : Enlace duro (por defecto): otro nombre para el mismo inodo; no puede
           cruzar sistemas de archivos ni apuntar a directorios, y el archivo
           no desaparece hasta borrar todos sus nombres.
           Enlace simbólico (-s): archivo especial que contiene una ruta; sí
           puede apuntar a directorios y a otros sistemas de archivos, pero se
           "rompe" si el destino se borra o mueve. Una ruta relativa se
           interpreta desde el directorio donde está el enlace, no desde el
           directorio actual.
OPCIONES :
  -s   Crea un enlace simbólico en lugar de uno duro.
  -f   Sobrescribe el enlace si ya existe.
  -r   Crea la ruta del enlace simbólico relativa (GNU).
  -v   Muestra lo que hace.
EJEMPLOS :
  ln -s /opt/app/bin/app ~/bin/app
  ln datos.txt copia_dura.txt
  ls -li datos.txt copia_dura.txt     # mismo inodo en ambos
EOF

# -----------------------------------------------------------------------------
# mv
# -----------------------------------------------------------------------------
RESUMEN[mv]="Mueve o renombra archivos y directorios."
IFS= read -r -d '' 'FICHA[mv]' <<'EOF'
SINTAXIS : mv [opciones] origen... destino
QUÉ HACE : Mueve archivos a otro directorio o los renombra si el destino es un
           nombre nuevo.
DETALLE  : Dentro del mismo sistema de archivos solo cambia la entrada del
           directorio (es instantáneo y conserva el inodo); entre sistemas
           distintos copia y luego borra. No necesita -r para directorios.
           Sobrescribe sin avisar salvo con -i o -n.
OPCIONES :
  -i   Pregunta antes de sobrescribir.
  -n   No sobrescribe.
  -u   Mueve solo si el origen es más nuevo o no existe en el destino.
  -v   Muestra lo que hace.
  -f   Fuerza, sin preguntar (es el comportamiento por defecto).
  -t DIR   Indica el directorio destino al principio.
EJEMPLOS :
  mv antiguo.txt nuevo.txt          # renombrar
  mv *.log /var/backups/            # mover varios
  mv -iv foto.jpg ~/Imágenes/
EOF

# -----------------------------------------------------------------------------
# rm
# -----------------------------------------------------------------------------
RESUMEN[rm]="Elimina archivos y directorios (sin papelera)."
IFS= read -r -d '' 'FICHA[rm]' <<'EOF'
SINTAXIS : rm [opciones] archivo...
QUÉ HACE : Borra las entradas indicadas del sistema de archivos.
DETALLE  : No hay papelera ni deshacer. `rm -rf` con una variable vacía o mal
           expandida puede ser desastroso (p. ej. rm -rf "$DIR"/ ). Para
           borrar archivos cuyo nombre empieza por guion, usar `--`:
           rm -- -archivo.
OPCIONES :
  -r, -R   Recursivo: borra directorios y su contenido.
  -f       Fuerza: no pregunta y no da error si no existe.
  -i       Pregunta antes de cada borrado.
  -I       Pregunta una sola vez si se borran más de 3 archivos o recursivo.
  -d       Borra directorios vacíos (como rmdir).
  -v       Muestra lo que va borrando.
EJEMPLOS :
  rm fichero.txt
  rm -i *.tmp
  rm -rI directorio_antiguo/
EOF

# -----------------------------------------------------------------------------
# mkdir
# -----------------------------------------------------------------------------
RESUMEN[mkdir]="Crea directorios."
IFS= read -r -d '' 'FICHA[mkdir]' <<'EOF'
SINTAXIS : mkdir [opciones] directorio...
QUÉ HACE : Crea uno o varios directorios.
DETALLE  : Con la expansión de llaves de bash se pueden crear estructuras
           completas en una sola orden.
OPCIONES :
  -p   Crea también los directorios padre que falten y no da error si el
       directorio ya existe.
  -m   Establece los permisos al crearlo (p. ej. -m 700).
  -v   Muestra cada directorio creado.
EJEMPLOS :
  mkdir datos
  mkdir -p proyecto/{src,docs,tests}
  mkdir -m 700 privado
EOF

# -----------------------------------------------------------------------------
# chmod
# -----------------------------------------------------------------------------
RESUMEN[chmod]="Cambia los permisos de archivos y directorios."
IFS= read -r -d '' 'FICHA[chmod]' <<'EOF'
SINTAXIS : chmod [opciones] modo archivo...
QUÉ HACE : Modifica los permisos de lectura (r), escritura (w) y ejecución (x)
           para el propietario (u), el grupo (g) y los otros (o).
DETALLE  : Modo octal: r=4, w=2, x=1; se suman por cada categoría (u, g, o).
           Así 755 = rwxr-xr-x y 644 = rw-r--r--.
           Modo simbólico: [ugoa][+-=][rwx], p. ej. u+x, go-w, a=r.
           En directorios, x significa poder entrar y acceder a su contenido.
           Solo el propietario o root pueden cambiar los permisos.
           La X mayúscula añade x solo a directorios (o archivos que ya la
           tengan). También existen los bits especiales: setuid (u+s), setgid
           (g+s) y sticky (+t).
OPCIONES :
  -R   Recursivo.
  -v   Muestra todos los cambios; -c solo los que realmente cambian algo.
  --reference=ARCHIVO   Copia los permisos de otro archivo.
EJEMPLOS :
  chmod 755 script.sh
  chmod u+x,go-w script.sh
  chmod -R u=rwX,go=rX proyecto/
  chmod +t /tmp/compartido
EOF

# -----------------------------------------------------------------------------
# chgrp
# -----------------------------------------------------------------------------
RESUMEN[chgrp]="Cambia el grupo propietario de archivos y directorios."
IFS= read -r -d '' 'FICHA[chgrp]' <<'EOF'
SINTAXIS : chgrp [opciones] grupo archivo...
QUÉ HACE : Cambia el grupo al que pertenece un archivo.
DETALLE  : (El comando se llama chgrp, no "chgroup".) Un usuario normal solo
           puede cambiarlo si es el propietario y pertenece al grupo de
           destino; root puede cambiarlo siempre. Es equivalente a
           `chown :grupo archivo`.
OPCIONES :
  -R   Recursivo.
  -v   Muestra todos los cambios; -c solo los que cambian algo.
  -h   Actúa sobre el enlace simbólico en sí, no sobre su destino.
  --reference=ARCHIVO   Usa el grupo de otro archivo.
EJEMPLOS :
  chgrp developers proyecto.txt
  chgrp -R www-data /var/www/sitio
EOF

# -----------------------------------------------------------------------------
# chown
# -----------------------------------------------------------------------------
RESUMEN[chown]="Cambia el propietario (y opcionalmente el grupo) de un archivo."
IFS= read -r -d '' 'FICHA[chown]' <<'EOF'
SINTAXIS : chown [opciones] [usuario][:grupo] archivo...
QUÉ HACE : Cambia el usuario propietario y, si se indica tras los dos puntos,
           también el grupo.
DETALLE  : Solo root puede cambiar el propietario de un archivo. Formas de uso:
           usuario        cambia solo el propietario
           usuario:grupo  cambia ambos
           usuario:       cambia el propietario y pone su grupo de login
           :grupo         cambia solo el grupo
OPCIONES :
  -R   Recursivo.
  -v   Muestra todos los cambios; -c solo los que cambian algo.
  -h   Actúa sobre el enlace simbólico en sí, no sobre su destino.
  --from=ACTUAL   Cambia solo si el propietario actual coincide.
  --reference=ARCHIVO   Copia propietario y grupo de otro archivo.
EJEMPLOS :
  sudo chown ana archivo.txt
  sudo chown -R www-data:www-data /var/www
  sudo chown :developers proyecto/
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
  -t C       Usa el carácter C como separador de campos.
  -V   Orden de versiones (1.2 < 1.10).
  -b   Ignora los espacios iniciales.
  -o FICHERO   Escribe el resultado en un archivo (válido incluso si es el mismo
               que el de entrada).
EJEMPLOS :
  sort nombres.txt
  sort -t: -k3,3n /etc/passwd          # por UID
  du -sh * | sort -rh | head
  sort -u lista.txt
EOF

# -----------------------------------------------------------------------------
# uniq
# -----------------------------------------------------------------------------
RESUMEN[uniq]="Filtra o cuenta líneas repetidas consecutivas."
IFS= read -r -d '' 'FICHA[uniq]' <<'EOF'
SINTAXIS : uniq [opciones] [entrada [salida]]
QUÉ HACE : Elimina las líneas duplicadas que estén seguidas.
DETALLE  : Solo detecta repeticiones adyacentes, por lo que casi siempre se usa
           tras `sort`: sort | uniq. El patrón `sort | uniq -c | sort -rn`
           produce un ranking de frecuencias.
OPCIONES :
  -c   Antepone el número de apariciones a cada línea.
  -d   Muestra solo las líneas repetidas (una vez cada una).
  -u   Muestra solo las líneas que no se repiten.
  -i   Ignora mayúsculas y minúsculas.
  -f N   Ignora los N primeros campos al comparar.
  -s N   Ignora los N primeros caracteres al comparar.
  -w N   Compara solo los N primeros caracteres.
EJEMPLOS :
  sort archivo.txt | uniq
  sort visitas.log | uniq -c | sort -rn | head
  sort lista.txt | uniq -d           # los duplicados
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
  -c LISTA       Selecciona caracteres por posición.
  -b LISTA       Selecciona bytes.
  --complement   Muestra todo excepto lo seleccionado.
  --output-delimiter=S   Usa S como separador en la salida.
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
  -l   Muestra solo los nombres de archivo con coincidencias (-L, los que no).
  -w   Coincide con palabras completas.
  -x   Coincide con la línea entera.
  -o   Muestra solo la parte que coincide.
  -E   Expresiones regulares extendidas.
  -F   Cadena fija, sin interpretar regex.
  -P   Expresiones regulares compatibles con Perl (GNU).
  -A N / -B N / -C N   Muestra N líneas después / antes / alrededor.
  -q   Silencioso: solo devuelve el código de salida.
  -h / -H   Oculta / muestra el nombre de archivo.
  --include=GLOB / --exclude=GLOB   Filtra archivos en búsquedas recursivas.
  --color=auto   Resalta las coincidencias.
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
DETALLE  : Con varios archivos escribe una cabecera con el nombre de cada uno.
           Con un número negativo en -n o -c (GNU) muestra todo menos las
           últimas N líneas o bytes.
OPCIONES :
  -n N    Las primeras N líneas (-n -N: todas menos las últimas N).
  -c N    Los primeros N bytes.
  -q      No muestra las cabeceras con los nombres de archivo.
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
DETALLE  : Su uso estrella es seguir un log en tiempo real con -f. Con -F
           sigue funcionando aunque el archivo se rote (se renombre y se
           recree), algo habitual en logs.
OPCIONES :
  -n N     Las últimas N líneas (-n +N: desde la línea N hasta el final).
  -c N     Los últimos N bytes.
  -f       Sigue el archivo y muestra las líneas nuevas según se añaden.
  -F       Como -f, pero reabre el archivo si se rota o se recrea.
  --pid=PID   Con -f, termina cuando acabe ese proceso.
  -q       No muestra las cabeceras con los nombres de archivo.
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
  -c   Usa el complemento de CONJUNTO1 (todo lo que NO esté en él).
  -t   Trunca CONJUNTO1 a la longitud de CONJUNTO2.
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
DETALLE  : Con varios archivos añade una línea final con los totales. Si lee de
           la entrada estándar, no imprime nombre de archivo, lo que facilita
           capturar el número: n=$(wc -l < archivo).
           Cuenta saltos de línea: un archivo sin salto final cuenta una
           línea menos.
OPCIONES :
  -l   Líneas.
  -w   Palabras.
  -c   Bytes.
  -m   Caracteres (difiere de -c con UTF-8 multibyte).
  -L   Longitud de la línea más larga.
EJEMPLOS :
  wc -l /etc/passwd
  ls | wc -l                 # número de elementos de un directorio
  wc -w ensayo.txt
EOF

# -----------------------------------------------------------------------------
# sed
# -----------------------------------------------------------------------------
RESUMEN[sed]="Editor de flujo: transforma texto línea a línea."
IFS= read -r -d '' 'FICHA[sed]' <<'EOF'
SINTAXIS : sed [opciones] 'script' [archivo...]
QUÉ HACE : Lee el texto línea a línea, aplica las órdenes del script y escribe
           el resultado. No modifica el archivo original salvo con -i.
DETALLE  : Su comando más usado es la sustitución: s/patrón/reemplazo/flags.
           El delimitador puede ser cualquier carácter (s|/usr|/opt|), útil con
           rutas. En el reemplazo, & representa lo encontrado y \1, \2... los
           grupos capturados. Una dirección delante limita dónde actúa:
           3 (línea 3), 2,5 (rango), $ (última), /patrón/ (líneas que casan).
           Ojo: `-i` sin sufijo no hace copia de seguridad y en macOS/BSD
           exige un argumento (-i '').
OPCIONES :
  -n        No imprime automáticamente; solo lo que pida la orden p.
  -i[SUF]   Edita el archivo en el sitio (con SUF guarda copia de seguridad).
  -e SCRIPT Añade un script; permite encadenar varias órdenes.
  -E        Expresiones regulares extendidas (usa ( ) + ? | sin escapar).
  -f ARCHIVO  Lee el script de un archivo.
COMANDOS :
  s/a/b/g   Sustituye (g = todas las veces en la línea, i = ignora mayúsculas).
  d         Borra la línea.
  p         Imprime la línea (se usa con -n).
  y/abc/xyz/  Transcribe caracteres, como tr.
  a TEXTO   Añade texto después / i antes / c cambia la línea.
EJEMPLOS :
  sed 's/rojo/azul/g' texto.txt
  sed -i.bak 's/foo/bar/g' config.txt
  sed -n '5,10p' archivo.txt             # imprime las líneas 5 a 10
  sed '/^#/d;/^$/d' conf.txt             # quita comentarios y líneas vacías
  sed -E 's/([0-9]+)-([0-9]+)/\2-\1/' datos.txt
EOF

# -----------------------------------------------------------------------------
# ps
# -----------------------------------------------------------------------------
RESUMEN[ps]="Muestra una instantánea de los procesos en ejecución."
IFS= read -r -d '' 'FICHA[ps]' <<'EOF'
SINTAXIS : ps [opciones]
QUÉ HACE : Lista los procesos del sistema con información como PID, usuario,
           uso de CPU y memoria, estado y comando.
DETALLE  : Sin opciones solo muestra los procesos de la terminal actual. Admite
           estilo POSIX (con guion: ps -ef) y estilo BSD (sin guion: ps aux).
           Ojo: pueden mezclarse, pero el significado cambia según el guion;
           por ejemplo, `ps -u yo` filtra por usuario, mientras que `ps u`
           solo activa el formato orientado al usuario.
           Es una foto fija; para ver la evolución usa `top` o `htop`.
           Estados (columna STAT): R ejecutándose, S durmiendo, D espera de E/S
           ininterrumpible, T detenido, Z zombi.
           Al filtrar con grep, el propio grep aparece en la lista; el truco
           `grep [n]ginx` o usar `pgrep` lo evita.
OPCIONES (estilo BSD, sin guion):
  a            Elimina la restricción de mostrar solo los procesos del usuario
               actual (incluye los de otros usuarios que tengan terminal).
  x            Elimina la restricción de mostrar solo los procesos lanzados
               desde la terminal actual (incluye los que no tienen terminal).
  ax           Lista los procesos de todos los usuarios en todas las terminales.
  u            Formato orientado al usuario (USER, %CPU, %MEM, START...).
               Por ejemplo: ps aux.
  f            Arte ASCII para destacar la jerarquía: qué procesos son hijos de
               otros. Por ejemplo: ps auxf.
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
  -H / --forest   Muestra el árbol de procesos padre-hijo (como la f de BSD).
  -L           Muestra los hilos (threads) de cada proceso.
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
# ps
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
  -i [filtro]   Conexiones de red: [4|6][protocolo][@host][:puerto].
  -U            Solo sockets de dominio UNIX.
  +D DIR        Todo lo abierto dentro de un directorio (recursivo).
  -t            Muestra solo los PID (modo terso, para usar con kill).
  -n / -P       No resuelve nombres de host / de puertos (más rápido).
  -a            Combina los filtros con AND.
  +L1           Archivos con 0 enlaces (borrados pero todavía abiertos).
  ARCHIVO       Procesos que tienen abierto ese archivo.
EJEMPLOS :
  sudo lsof -i :8080                 # quién usa el puerto 8080
  lsof -i TCP -sTCP:LISTEN -P -n     # puertos TCP en escucha
  lsof /var/log/syslog
  lsof -p 1234
  lsof +L1                           # espacio ocupado por archivos borrados
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
  --check-order / --nocheck-order   Comprueba o no que la entrada está ordenada.
  --output-delimiter=S   Usa S como separador de columnas (por defecto, tab).
  -z   Usa el byte nulo como fin de línea.
EJEMPLOS :
  comm -12 <(sort a.txt) <(sort b.txt)    # líneas en ambos
  comm -23 <(sort a.txt) <(sort b.txt)    # líneas solo en a.txt
  comm -3 a_ordenado.txt b_ordenado.txt   # lo que difiere
EOF

# -----------------------------------------------------------------------------
# awk
# -----------------------------------------------------------------------------
RESUMEN[awk]="Lenguaje para procesar texto por campos: patrones, acciones y cálculos."
IFS= read -r -d '' 'FICHA[awk]' <<'EOF'
SINTAXIS : awk [opciones] 'programa' [archivo...]
           awk [opciones] -f programa.awk [archivo...]
QUÉ HACE : Lee la entrada registro a registro (por defecto, una línea) y divide
           cada registro en campos ($1, $2...). Por cada registro evalúa una
           lista de reglas "patrón { acción }" y ejecuta la acción de las
           reglas cuyo patrón se cumple. Es un lenguaje de programación
           completo: variables, arrays asociativos, funciones, bucles,
           expresiones regulares y E/S. Sirve para extraer columnas, filtrar,
           sumar, contar, agrupar, reformatear, comparar archivos y generar
           informes, todo en una línea.
DETALLE  : - Sin patrón, la acción se aplica a todas las líneas. Sin acción, se
             imprime la línea completa ({ print $0 }). Por eso '$3 > 10'
             filtra, y '1' (condición siempre verdadera) imprime todo.
           - El programa va entre comillas simples para que la shell no
             toque $1, $2... Las cadenas dentro del programa llevan comillas
             dobles. Para pasar valores de la shell: -v var="$valor" o la
             tabla ENVIRON; no pongas "$variable" de la shell dentro del
             programa.
           - Las variables no inicializadas valen 0 (en número) y "" (en
             cadena); no hay que declararlas.
           - Una condición es falsa si vale 0 o "" (cadena vacía).
           - Los campos que parecen números se comparan como números;
             si no, como cadenas. Para forzar: $1+0 (número) o $1"" (cadena).
           - Las reglas se evalúan en orden para cada línea; "next" salta a la
             siguiente línea sin evaluar el resto de reglas.
           - Existen varias implementaciones: gawk (GNU), mawk (el awk por
             defecto en Debian/Ubuntu), el awk de BWK (macOS/BSD) y busybox.
             Lo marcado [gawk] solo funciona en gawk.
OPCIONES :
  -F SEP        Separador de campos de entrada (FS). Un solo carácter se usa
                tal cual (-F: -F, -F'|' -F'\t'); si es más largo se interpreta
                como expresión regular (-F'[,;]' -F', *' -F'::'). Por defecto:
                cualquier secuencia de espacios y tabuladores.
  -v VAR=VAL    Asigna una variable antes de empezar (disponible en BEGIN).
  -f ARCHIVO    Lee el programa de un archivo (puede repetirse).
  --            Fin de opciones (útil si un archivo empieza por guion).
  VAR=VAL       Entre los archivos, asigna la variable al llegar a ese punto
                (permite cambiar FS entre un archivo y otro).
  -i inplace    [gawk] Edita el archivo en el sitio, como sed -i.
  --csv         [gawk 5.3+] Interpreta CSV con comillas correctamente.
  --version     Muestra la versión e implementación.
ESTRUCTURA DEL PROGRAMA :
  BEGIN { ... }      Se ejecuta una vez, antes de leer nada (inicializar
                     variables, imprimir cabeceras, cambiar FS/OFS).
  patrón { ... }     Se ejecuta por cada registro que cumpla el patrón.
  END { ... }        Se ejecuta una vez, tras leer todo (totales, informes).
                     Dentro de END, $0 y NF conservan la última línea leída.
  function f(a,b) {...}   Funciones definidas por el usuario.
  [gawk] BEGINFILE / ENDFILE   Al empezar / terminar cada archivo.
  # comentario       Hasta fin de línea. Las instrucciones se separan con ; o
                     salto de línea. Una \ al final continúa la línea.
PATRONES :
  (vacío)            Todas las líneas.
  /regex/            Líneas que contienen la expresión regular.
  !/regex/           Líneas que NO la contienen.
  $2 ~ /regex/       El campo 2 casa con la regex (!~ para negar).
  $3 > 100           Cualquier expresión relacional o lógica.
  NR==1  NR>1  NR%2==0   Por número de línea (primera, sin cabecera, pares).
  p1 && p2   p1 || p2   !p   Combinaciones lógicas.
  /ini/,/fin/        Rango: desde la línea que casa con ini hasta la que casa
                     con fin (ambas incluidas); se repite si vuelve a casar.
  $1 in array        Si la clave existe en un array.
VARIABLES INTEGRADAS :
  $0            La línea (registro) completa.
  $1, $2, ...   Campos de la línea. $NF es el último y $(NF-1) el penúltimo.
                Ojo: $NF-1 significa (valor del último campo) menos 1.
  NF            Número de campos de la línea actual.
  NR            Número de registro acumulado de todos los archivos.
  FNR           Número de registro dentro del archivo actual.
  FS            Separador de campos de entrada (equivale a -F).
  OFS           Separador de campos de salida (por defecto, un espacio); se
                usa en print con comas y al reconstruir $0.
  RS            Separador de registros de entrada (por defecto, \n). Con
                RS="" el modo párrafo separa registros por líneas en blanco.
  ORS           Separador de registros de salida (por defecto, \n).
  FILENAME      Nombre del archivo que se está leyendo.
  ENVIRON       Array con las variables de entorno: ENVIRON["HOME"].
  ARGC, ARGV    Número y array de argumentos de la línea de comandos.
  SUBSEP        Separador de índices múltiples en arrays (a[i,j]).
  RSTART, RLENGTH   Posición y longitud de la última coincidencia de match().
  CONVFMT, OFMT     Formato de conversión de números a cadena / al imprimir.
  [gawk] IGNORECASE  Si es distinto de 0, regex y comparaciones ignoran
                     mayúsculas. [gawk] RT: texto que casó con RS.
  [gawk] FPAT / FIELDWIDTHS  Define los campos por su contenido / anchura.
  [gawk] PROCINFO    Información del proceso y control (orden de recorrido).
OPERADORES (de mayor a menor precedencia, aproximadamente) :
  ( )  $  ++ --  ^ (o ** en gawk)  ! + - (unarios)  * / %  + -
  concatenación (poner dos expresiones juntas: a b)  < <= == != > >=
  ~ !~  in  &&  ||  ?:  = += -= *= /= %= ^=
CAMPOS Y REGISTROS :
  - Asignar un campo ($3="x") o modificar NF reconstruye $0 usando OFS.
  - Asignar $0 vuelve a dividir la línea en campos con FS.
  - Cambiar OFS no tiene efecto visible hasta que se reconstruye $0: la
    instrucción $1=$1 lo fuerza (por eso '{$1=$1}1' normaliza espacios).
  - Asignar un campo inexistente ($10="x" con 5 campos) crea campos vacíos.
  - print a, b separa con OFS; print a b los concatena sin separador.
INSTRUCCIONES :
  print expr, expr    Imprime separando con OFS y terminando con ORS.
  printf fmt, args    Salida con formato de C (%s %d %f %5.2f %-10s %x %c %%).
                      No añade salto de línea: hay que poner \n.
  if (c) ... else ...      while (c) ...      do ... while (c)
  for (i=1; i<=NF; i++) ...        for (clave in array) ...
  break  continue
  next          Descarta la línea actual y pasa a la siguiente.
  nextfile      Salta al siguiente archivo.
  exit [código] En una regla salta a END; dentro de END termina el programa.
  delete a[k]   Borra un elemento (delete a borra todo el array).
  return        Devuelve un valor desde una función.
  { instr; instr }   Las llaves agrupan instrucciones.
  [gawk] switch (x) { case 1: ... default: ... }
ARRAYS ASOCIATIVOS :
  - Los índices son cadenas: contador[$1]++, nombre["ana"]="Ana".
  - Existe? (k in a)  No crea el elemento; en cambio, consultar a[k] sí lo crea.
  - Índices múltiples: a[i,j] y (i,j) in a (se unen con SUBSEP).
  - for (k in a) recorre sin orden definido. Para ordenar, redirigir a sort
    o, en gawk, PROCINFO["sorted_in"]="@ind_str_asc" (o "@val_num_desc").
  - length(a) da el número de elementos.
FUNCIONES DE CADENAS :
  length(s)            Longitud (sin argumento, la de $0).
  substr(s, i, n)      Subcadena desde la posición i (empieza en 1), n caracteres.
  index(s, t)          Posición de t dentro de s (0 si no está).
  split(s, a, sep)     Trocea s en el array a (a[1]...a[n]); devuelve n.
  sub(/re/, rep, t)    Sustituye la primera coincidencia (por defecto en $0).
  gsub(/re/, rep, t)   Sustituye todas. En rep, & es el texto encontrado
                       (\\& para un & literal). Devuelven el nº de cambios.
  match(s, /re/)       Devuelve la posición (0 si no casa); fija RSTART y RLENGTH.
  sprintf(fmt, ...)    Como printf, pero devuelve la cadena.
  tolower(s) toupper(s)   Pasan a minúsculas / mayúsculas.
  [gawk] gensub(re, rep, n, s)   Sustituye con grupos (\1, \2) y sin
                       modificar el original.
FUNCIONES NUMÉRICAS :
  int(x)  sqrt(x)  exp(x)  log(x)  sin(x)  cos(x)  atan2(y,x)
  rand()  Número aleatorio en [0,1). srand(n) fija la semilla (srand() usa
          la hora; sin srand(), la secuencia siempre es la misma).
FUNCIONES DE E/S Y SISTEMA :
  getline               Lee la siguiente línea en $0 (actualiza NF, NR, FNR).
  getline var           Lee la siguiente línea en var.
  getline < archivo     Lee una línea de un archivo (o getline var < archivo).
  comando | getline     Lee una línea de la salida de un comando.
                        Devuelve 1 (leyó), 0 (fin) o -1 (error): usar
                        while ((getline l < f) > 0) para evitar bucles infinitos.
  print ... > "archivo"    Escribe en un archivo (lo vacía solo al abrirlo la
                           primera vez); >> añade; | "comando" envía a un comando.
  close(x)              Cierra un archivo o tubería (necesario para releer el
                        archivo o para que el comando termine, p. ej. sort).
  system(comando)       Ejecuta un comando de la shell; devuelve su estado.
  fflush()              Vacía los búferes de salida.
  [gawk] systime(), strftime(fmt, t), mktime("AAAA MM DD HH MM SS")
  [gawk] asort(a), asorti(a)   Ordenan un array por valores / por índices.
FUNCIONES DEL USUARIO :
  function nombre(p1, p2,    local1, local2) {
      ...
      return valor
  }
  Los parámetros que sobran en la llamada (aquí local1, local2) funcionan
  como variables locales; el resto de variables son globales. Los arrays
  se pasan por referencia y los escalares por valor.
EJEMPLOS : Columnas y campos
  awk '{print $1}' archivo                  # primera columna
  awk '{print $1, $NF}' archivo             # primera y última
  awk '{print $(NF-1)}' archivo             # penúltima
  awk -F: '{print $1, $3}' /etc/passwd      # usuario y UID
  awk -F: -v OFS='\t' '{print $1, $3}' /etc/passwd
  awk -F, '{print $2}' datos.csv
  awk '{$2=""; print}' archivo              # elimina la columna 2
  awk '{print NF}' archivo                  # nº de campos de cada línea
  awk '{$1=$1}1' archivo                    # normaliza espacios
  awk -v OFS=, '{$1=$1}1' archivo           # espacios -> comas
  awk -F'\t' -v OFS=, '{$1=$1}1' tsv.txt    # TSV -> CSV sencillo
EJEMPLOS : Filtrar líneas
  awk '$3 > 100' archivo
  awk '$1 == "root"' /etc/passwd
  awk -F: '$3 >= 1000 {print $1}' /etc/passwd   # usuarios normales
  awk '/error/' log                         # como grep
  awk '!/error/' log                        # como grep -v
  awk '$2 ~ /^a/' archivo                   # campo 2 empieza por a
  awk 'NR==5' archivo                       # solo la línea 5
  awk 'NR>=5 && NR<=10' archivo
  awk 'NR>1' datos.csv                      # sin la cabecera
  awk 'NR%2==0' archivo                     # líneas pares
  awk 'NF' archivo                          # quita líneas vacías
  awk 'length > 80' archivo                 # líneas largas
  awk '/inicio/,/fin/' archivo              # rango entre dos patrones
  awk 'END{print}' archivo                  # última línea
EJEMPLOS : Cálculos
  awk 'END{print NR}' archivo               # nº de líneas (wc -l)
  awk '{s+=$1} END{print s}' archivo        # suma
  awk '{s+=$1} END{print s/NR}' archivo     # media
  awk '{s+=$1} END{printf "%.2f\n", s}' archivo
  awk 'NR==1||$1>m{m=$1} END{print m}' archivo     # máximo
  awk 'NR==1||$1<m{m=$1} END{print m}' archivo     # mínimo
  awk '{w+=NF} END{print w}' archivo        # nº de palabras
  awk 'BEGIN{print 2^10, 10/3, int(10/3)}'  # awk como calculadora
EJEMPLOS : Agrupar y contar (arrays asociativos)
  awk '{c[$1]++} END{for (k in c) print k, c[k]}' archivo      # contar por clave
  awk '{t[$1]+=$2} END{for (k in t) print k, t[k]}' archivo    # sumar por clave
  awk '{s[$1]+=$2; n[$1]++} END{for (k in s) print k, s[k]/n[k]}' archivo
  awk '{for(i=1;i<=NF;i++) f[tolower($i)]++} END{for(w in f) print f[w], w}' t | sort -rn | head
  awk '!seen[$0]++' archivo                 # elimina duplicados sin ordenar
  awk '!seen[$1]++' archivo                 # primera línea de cada valor de $1
EJEMPLOS : Texto y formato
  awk '{print toupper($1)}' archivo
  awk '{gsub(/foo/, "bar")} 1' archivo      # como sed 's/foo/bar/g'
  awk '{print length($0)}' archivo          # longitud de cada línea
  awk '{print substr($1, 1, 3)}' archivo
  awk '{print NR": "$0}' archivo            # numera líneas
  awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) print a[i]}' archivo    # como tac
  awk '{for(i=NF;i>=1;i--) printf "%s%s", $i, (i>1 ? OFS : ORS)}' archivo
  awk '{printf "%-10s %5d\n", $1, $2}' archivo
  awk 'BEGIN{FS=":"; printf "%-12s %s\n","USUARIO","UID"} {printf "%-12s %s\n",$1,$3}' /etc/passwd
  awk '{n=split($0, p, ","); print p[n]}' archivo   # último elemento separado por comas
EJEMPLOS : Varios archivos
  awk 'FNR==1{print FILENAME}' *.txt        # nombre al empezar cada archivo
  awk 'FNR>1 || NR==1' a.csv b.csv          # une CSV conservando una cabecera
  awk 'NR==FNR{a[$1]=$2; next} $1 in a {print $0, a[$1]}' ref datos   # "join"
  awk 'NR==FNR{a[$0]; next} !($0 in a)' f1 f2    # líneas de f2 que no están en f1
  awk 'NR==FNR{a[$0]; next} ($0 in a)' f1 f2     # líneas comunes
EJEMPLOS : Con variables de la shell y con comandos
  awk -v min="$MIN" '$3 > min' datos        # pasa una variable de la shell
  awk -v u="$USER" '$1 == u' datos
  awk 'BEGIN{print ENVIRON["HOME"]}'
  ps aux | awk '$3 > 50 {print $2, $11}'              # procesos con más de 50% CPU
  ps aux | awk 'NR>1{s+=$6} END{print s/1024 " MB"}'  # memoria RSS total
  df -h | awk 'NR>1 && $5+0 > 80 {print $6, $5}'      # discos con más de 80%
  ls -l | awk 'NR>1{s+=$5} END{print s}'              # bytes totales
  last | awk '{c[$1]++} END{for(u in c) print c[u], u}' | sort -rn
EJEMPLOS : Salida a archivos y a comandos
  awk '{print > ($1 ".txt")}' archivo       # un archivo por cada valor de $1
  awk '{print $1 | "sort -u"}' archivo      # envía la salida a otro comando
  awk 'BEGIN{while (("date" | getline d) > 0) print "Hoy: " d}'
  awk 'BEGIN{srand(); print int(rand()*100)}'    # aleatorio entre 0 y 99
EJEMPLOS : Programas largos y gawk
  awk -f informe.awk datos.txt              # programa guardado en un archivo
  awk '/error/ {n++} END {if (n > 0) exit 1}' log   # exit con código de error
  gawk -i inplace '{gsub(/a/,"b")}1' archivo        # edición en el sitio
  gawk '{print strftime("%F %T", $1)}' tiempos      # epoch -> fecha legible
  gawk '{c[$1]++} END{PROCINFO["sorted_in"]="@val_num_desc"; for(k in c) print c[k], k}' f
  gawk -v FPAT='([^,]+)|("[^"]+")' '{print $2}' datos.csv   # CSV con comillas
EOF

# -----------------------------------------------------------------------------
# diff
# -----------------------------------------------------------------------------
RESUMEN[diff]="Compara dos archivos (o directorios) y muestra sus diferencias."
IFS= read -r -d '' 'FICHA[diff]' <<'EOF'
SINTAXIS : diff [opciones] archivo1 archivo2
QUÉ HACE : Calcula las diferencias línea a línea entre dos archivos y muestra qué
           habría que cambiar en el primero para obtener el segundo.
DETALLE  : Formato normal: líneas como 3c3, 5a6 o 8d7 (a = añadir, c = cambiar,
           d = borrar), con "<" para líneas del archivo 1 y ">" para las del
           archivo 2. El formato unificado (-u) es el más usado y es el que
           emplean git y `patch`: líneas con "-" (solo en el 1), "+" (solo en
           el 2) y " " (contexto), agrupadas en bloques que empiezan por @@.
           A diferencia de `comm`, no exige que los archivos estén ordenados y
           respeta el orden de las líneas.
           Código de salida: 0 = iguales, 1 = diferentes, 2 = error.
OPCIONES :
  -u         Formato unificado (el más legible y el estándar para parches).
  -c         Formato de contexto.
  -y         Dos columnas lado a lado (-W N fija el ancho; --suppress-common-lines
             oculta las líneas iguales).
  -r         Recursivo: compara directorios completos.
  -q         Solo indica si los archivos difieren, sin mostrar las diferencias.
  -s         Indica también cuando los archivos son idénticos.
  -i         Ignora diferencias entre mayúsculas y minúsculas.
  -w         Ignora todos los espacios en blanco.
  -b         Ignora cambios en la cantidad de espacios.
  -B         Ignora las líneas en blanco.
  -N         Trata los archivos ausentes como vacíos (con -r).
  -x PATRÓN  Excluye archivos que casen con el patrón (con -r).
  --color    Colorea la salida.
EJEMPLOS :
  diff antiguo.txt nuevo.txt
  diff -u antiguo.txt nuevo.txt
  diff -u original.c modificado.c > cambios.patch   # crear un parche
  patch < cambios.patch                             # aplicarlo
  diff -rq dir1/ dir2/                              # qué archivos difieren
  diff -y --suppress-common-lines a.txt b.txt
  diff <(sort a.txt) <(sort b.txt)                  # comparar tras ordenar
  diff -q a b && echo "iguales"
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
DETALLE  : La carga media (load average) son tres valores: promedio de procesos
           listos para ejecutar (o esperando E/S en Linux) en el último
           minuto, 5 y 15. Se compara con el número de CPU (nproc): una carga
           sostenida mayor que ese número indica saturación.
           Columnas: USER (usuario), TTY (terminal), FROM (origen remoto),
           LOGIN@ (hora de entrada), IDLE (inactividad), JCPU (CPU total de
           todos los procesos de esa terminal), PCPU (CPU del proceso actual)
           y WHAT (comando en ejecución).
           Relacionados: `who` (solo quién), `uptime` (solo la primera línea) y
           `last` (histórico de sesiones).
OPCIONES :
  -h   No muestra la cabecera.
  -s   Formato corto: omite LOGIN@, JCPU y PCPU.
  -f   Activa o desactiva la columna FROM.
  -i   Muestra la dirección IP en lugar del nombre de host en FROM.
  -u   Ignora el nombre de usuario al calcular JCPU y PCPU.
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
           El UID 0 es root. Cada proceso tiene un ID real y uno efectivo
           (distintos en programas setuid); id muestra por defecto el efectivo
           y -r el real. `whoami` equivale a `id -un`. Es muy útil en scripts
           para comprobar que se ejecutan como root o con ciertos grupos.
OPCIONES :
  -u   Solo el UID.
  -g   Solo el GID del grupo principal.
  -G   Los identificadores de todos los grupos.
  -n   Muestra nombres en vez de números (con -u, -g o -G).
  -r   Usa el ID real en vez del efectivo.
  -Z   Contexto de seguridad (SELinux).
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
# kill
# -----------------------------------------------------------------------------
RESUMEN[kill]="Envía una señal a procesos (por defecto, pide que terminen)."
IFS= read -r -d '' 'FICHA[kill]' <<'EOF'
SINTAXIS : kill [-señal] PID...      kill -l [número|nombre]
QUÉ HACE : Envía una señal a uno o varios procesos. Si no se indica ninguna,
           envía SIGTERM (15), que pide al proceso que termine y le deja
           limpiar antes de salir.
DETALLE  : El nombre "kill" es engañoso: puede enviar cualquier señal. Es un
           builtin de bash (también existe /bin/kill) y admite trabajos con
           %: kill %1. Lo normal es probar primero TERM, esperar un poco y
           solo entonces usar KILL. Con usuarios normales solo se puede
           señalar a los propios procesos; para el resto hace falta sudo.
           Un proceso zombi no se puede matar (hay que actuar sobre su padre)
           y uno en estado D (E/S ininterrumpible) no responde hasta que
           termine la operación.
           Es mejor usar nombres de señal que números, porque algunos números
           varían entre arquitecturas.
SEÑALES COMUNES :
  1  HUP    Cuelgue de terminal; en servicios suele significar "recarga la
            configuración".
  2  INT    Interrupción (la que envía Ctrl+C).
  3  QUIT   Terminar y volcar memoria (core dump); Ctrl+\
  9  KILL   Terminación inmediata: no se puede capturar ni ignorar, y el
            proceso no puede limpiar. Último recurso.
  15 TERM   Terminación ordenada (valor por defecto).
  18 CONT   Reanuda un proceso detenido.
  19 STOP   Detiene el proceso (no se puede capturar ni ignorar).
  20 TSTP   Suspensión desde el teclado (Ctrl+Z); sí se puede capturar.
  USR1 / USR2   Señales para uso de la aplicación (por ejemplo, rotar logs).
OPCIONES :
  -l [señal]      Lista las señales, o convierte entre número y nombre.
  -s SEÑAL        Indica la señal por su nombre (kill -s TERM 1234).
  -SEÑAL / -N     Atajo: kill -9 1234, kill -SIGKILL 1234, kill -KILL 1234.
  -0 (señal 0)    No envía nada: comprueba si el proceso existe y si se tiene
                  permiso para señalarlo.
VALORES ESPECIALES DE PID :
  0     Todos los procesos del grupo del proceso actual.
  -1    Todos los procesos a los que se tiene permiso (¡peligroso!).
  -N    Con -- delante, el grupo de procesos N: kill -- -1234.
  %N    Un trabajo de la shell: kill %1.
EJEMPLOS :
  kill 1234                          # SIGTERM
  kill -9 1234                       # SIGKILL
  kill -HUP "$(pidof nginx)"         # recargar configuración
  kill -STOP 1234; kill -CONT 1234   # pausar y reanudar
  kill -0 1234 && echo "existe"
  kill -l
  kill -- -1234                      # todo el grupo de procesos 1234
  kill %2                            # un trabajo en segundo plano
EOF

# -----------------------------------------------------------------------------
# pkill
# -----------------------------------------------------------------------------
RESUMEN[pkill]="Envía una señal a procesos buscándolos por nombre u otros criterios."
IFS= read -r -d '' 'FICHA[pkill]' <<'EOF'
SINTAXIS : pkill [-señal] [opciones] patrón
QUÉ HACE : Como `kill`, pero en lugar de usar el PID selecciona los procesos
           cuyo nombre coincide con una expresión regular. Envía SIGTERM por
           defecto.
DETALLE  : La coincidencia es parcial: `pkill ssh` también afecta a sshd o
           ssh-agent. Para evitarlo se usa -x (nombre exacto). Por defecto
           solo se compara con el nombre del proceso (los primeros 15
           caracteres); con -f se compara con la línea de comandos completa.
           Antes de matar, conviene probar los criterios con `pgrep -a`, que
           admite las mismas opciones y solo lista. pkill no se mata a sí
           mismo.
OPCIONES :
  -SEÑAL    Señal a enviar: pkill -9 nombre, pkill -HUP nginx (también -s).
  -f        Busca en la línea de comandos completa, no solo en el nombre.
  -x        El nombre debe coincidir exactamente.
  -i        Ignora mayúsculas y minúsculas.
  -u USER   Solo procesos de ese usuario.
  -P PPID   Solo hijos de ese proceso padre.
  -t TTY    Solo procesos de esa terminal.
  -n / -o   Solo el más reciente / el más antiguo de los que coinciden.
  -v        Invierte la selección (todos menos los que coinciden).
EJEMPLOS :
  pkill firefox
  pkill -x nginx                     # solo procesos llamados exactamente nginx
  pkill -9 -f "python3 servidor.py"  # por línea de comandos completa
  pkill -u ana                       # todos los procesos del usuario ana
  pkill -HUP -x sshd
  pkill -P 1234                      # los hijos del proceso 1234
EOF

# -----------------------------------------------------------------------------
# pgrep
# -----------------------------------------------------------------------------
RESUMEN[pgrep]="Busca procesos por nombre u otros criterios y muestra sus PID."
IFS= read -r -d '' 'FICHA[pgrep]' <<'EOF'
SINTAXIS : pgrep [opciones] patrón
QUÉ HACE : Lista los PID de los procesos cuyo nombre coincide con una expresión
           regular. Es la forma limpia de hacer `ps aux | grep nombre`, y,
           a diferencia de esa tubería, no se encuentra a sí mismo.
DETALLE  : Comparte criterios y opciones con `pkill`. Devuelve 0 si encontró
           algún proceso y 1 si no, así que sirve en condiciones:
           if pgrep -x nginx > /dev/null; then ...
           Compara con el nombre del proceso (primeros 15 caracteres) salvo
           que se use -f. Para varios PID en una línea separados por comas,
           útil con top -p, usar -d,.
OPCIONES :
  -l   Muestra también el nombre del proceso.
  -a   Muestra la línea de comandos completa.
  -f   Compara con la línea de comandos completa.
  -x   Coincidencia exacta del nombre.
  -i   Ignora mayúsculas y minúsculas.
  -u USER   Solo procesos de ese usuario.
  -P PPID   Solo hijos de ese proceso padre.
  -t TTY    Solo procesos de esa terminal.
  -n / -o   Solo el más reciente / el más antiguo.
  -c   Muestra solo cuántos procesos coinciden.
  -d S Usa S como delimitador entre los PID de la salida.
  -v   Invierte la selección.
EJEMPLOS :
  pgrep nginx
  pgrep -a python                    # PID y línea de comandos completa
  pgrep -u ana -l                    # procesos de ana con su nombre
  pgrep -x sshd -c                   # cuántos sshd hay
  top -p "$(pgrep -d, nginx)"        # monitorizar esos procesos en top
  pgrep -f "servidor.py" > /dev/null || echo "no está en marcha"
EOF

# -----------------------------------------------------------------------------
# top
# -----------------------------------------------------------------------------
RESUMEN[top]="Monitor interactivo de procesos y recursos del sistema en tiempo real."
IFS= read -r -d '' 'FICHA[top]' <<'EOF'
SINTAXIS : top [opciones]
QUÉ HACE : Muestra una vista que se actualiza periódicamente con el estado
           global del sistema y la lista de procesos, por defecto ordenada
           por uso de CPU.
DETALLE  : Cabecera:
             - hora, tiempo encendido, usuarios y carga media (como `w`);
             - Tareas: total, running (ejecutándose), sleeping, stopped y zombie;
             - %Cpu(s): us (usuario), sy (núcleo), ni (procesos con nice),
               id (inactiva), wa (esperando E/S), hi/si (interrupciones) y
               st (robado por el hipervisor en máquinas virtuales);
             - memoria y swap: total, libre, usada y buff/cache; "avail Mem"
               estima cuánta memoria hay realmente disponible.
           Columnas: PID, USER, PR (prioridad), NI (valor nice), VIRT (memoria
           virtual), RES (memoria física residente), SHR (compartida), S (estado:
           R, S, D, T, Z), %CPU, %MEM, TIME+ (CPU acumulada) y COMMAND.
           Con -H cada fila es un hilo y no un proceso. Una alternativa más
           cómoda es `htop`.
OPCIONES :
  -b          Modo batch: salida de texto sin interactividad (para redirigir
              o usar en scripts).
  -n N        Termina tras N actualizaciones (con -b: top -b -n 1).
  -d SEG      Intervalo entre actualizaciones.
  -p PID,...  Muestra solo esos procesos (hasta 20).
  -u USUARIO  Muestra solo los procesos de ese usuario.
  -H          Muestra los hilos (threads) individuales.
  -o CAMPO    Ordena por un campo: top -o %MEM.
  -c          Muestra la línea de comandos completa en COMMAND.
TECLAS INTERACTIVAS :
  q            Salir.                      h / ?   Ayuda.
  P / M / N / T   Ordenar por CPU / memoria / PID / tiempo.
  R            Invertir el orden.          1       CPU por núcleo.
  H            Alternar procesos / hilos.  c       Comando completo o solo nombre.
  u            Filtrar por usuario.        V       Vista de árbol de procesos.
  k            Enviar una señal (pide PID y señal; por defecto 15).
  r            Cambiar la prioridad (renice) de un proceso.
  d / s        Cambiar el intervalo de refresco.
  f            Elegir las columnas y el campo de ordenación.
  Espacio      Refrescar ahora.            W       Guardar la configuración.
EJEMPLOS :
  top
  top -u ana
  top -o %MEM
  top -H -p 1234                       # hilos de un proceso
  top -b -n 1 | head -15               # instantánea para un script o informe
  top -b -n 1 -o %MEM | head -12       # los que más memoria usan
EOF

# -----------------------------------------------------------------------------
# jobs
# -----------------------------------------------------------------------------
RESUMEN[jobs]="Lista los trabajos (procesos en segundo plano o detenidos) de la shell."
IFS= read -r -d '' 'FICHA[jobs]' <<'EOF'
SINTAXIS : jobs [opciones] [%trabajo...]
QUÉ HACE : Muestra los trabajos de la sesión de shell actual: los que se han
           lanzado en segundo plano con & y los que se han detenido con
           Ctrl+Z, con su número, estado (Running, Stopped, Done) y comando.
DETALLE  : Es un comando interno de bash y solo ve los trabajos de ESA shell,
           no los procesos del sistema (para eso, `ps`). El control de
           trabajos funciona así:
             comando &      lanza el comando en segundo plano
             Ctrl+Z         suspende el proceso en primer plano (SIGTSTP)
             bg             reanuda un trabajo detenido en segundo plano
             fg             trae un trabajo a primer plano
             $!             PID del último trabajo lanzado en segundo plano
             wait           espera a que terminen los trabajos
             disown         saca un trabajo de la tabla (no recibirá SIGHUP al
                            cerrar la shell); disown -h lo protege sin quitarlo
             nohup cmd &    ejecuta ignorando el cierre de la terminal
           Un trabajo en segundo plano que intenta leer del teclado se detiene.
           En la lista, "+" marca el trabajo actual y "-" el anterior.
ESPECIFICAR UN TRABAJO :
  %N      Trabajo número N.            %% o %+   El trabajo actual.
  %-      El anterior.                 %texto    El que empieza por texto.
  %?texto El que contiene texto.
OPCIONES :
  -l   Muestra también los PID.
  -p   Muestra solo los PID.
  -r   Solo los que están en ejecución.
  -s   Solo los detenidos.
  -n   Solo los que han cambiado de estado desde el último aviso.
EJEMPLOS :
  sleep 300 &                  # lanza en segundo plano
  jobs -l
  jobs -p | xargs kill         # termina todos los trabajos de la shell
  kill %2                      # termina el trabajo 2
  fg %1                        # lo trae a primer plano
EOF

# -----------------------------------------------------------------------------
# bg
# -----------------------------------------------------------------------------
RESUMEN[bg]="Reanuda un trabajo detenido y lo deja ejecutándose en segundo plano."
IFS= read -r -d '' 'FICHA[bg]' <<'EOF'
SINTAXIS : bg [%trabajo...]
QUÉ HACE : Envía SIGCONT a un trabajo detenido (por ejemplo, con Ctrl+Z) para que
           siga ejecutándose en segundo plano, devolviendo el control de la
           terminal al usuario.
DETALLE  : Es un comando interno de bash. Sin argumentos actúa sobre el trabajo
           actual (el marcado con + en `jobs`). Equivale a lanzar el comando
           con & desde el principio, pero después de haberlo suspendido.
           Si el proceso escribe en la terminal, su salida seguirá
           apareciendo en ella; si necesita leer del teclado, volverá a
           detenerse. Para que sobreviva al cierre de la terminal, usar
           además `disown`.
EJEMPLOS :
  comando_largo            # se ejecuta en primer plano
  # pulsa Ctrl+Z           -> queda detenido: [1]+ Stopped
  bg                       # sigue ejecutándose en segundo plano
  bg %2                    # reanuda el trabajo 2
  jobs                     # comprueba que está Running
EOF

# -----------------------------------------------------------------------------
# fg
# -----------------------------------------------------------------------------
RESUMEN[fg]="Trae un trabajo al primer plano de la terminal."
IFS= read -r -d '' 'FICHA[fg]' <<'EOF'
SINTAXIS : fg [%trabajo]
QUÉ HACE : Pone un trabajo (en segundo plano o detenido) en primer plano: recibe
           el teclado y la shell espera a que termine. Si estaba detenido, lo
           reanuda enviándole SIGCONT.
DETALLE  : Es un comando interno de bash. Sin argumentos actúa sobre el trabajo
           actual (marcado con + en `jobs`). Una vez en primer plano, Ctrl+C
           lo termina (SIGINT) y Ctrl+Z lo vuelve a detener (SIGTSTP). El
           trabajo se indica con el mismo formato que en `jobs`: %1, %%, %-,
           %texto, %?texto.
EJEMPLOS :
  fg                       # el trabajo actual
  fg %2                    # el trabajo número 2
  fg %vim                  # el trabajo cuyo comando empieza por "vim"
  sleep 100 &              # lanza en segundo plano
  fg                       # y lo trae al primer plano
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
           archivos recorriéndolos. Por defecto cuenta el espacio realmente
           reservado en disco (bloques), que puede diferir del tamaño
           "aparente" (--apparent-size), por ejemplo en archivos dispersos
           (sparse). Los enlaces duros se cuentan una sola vez. Sin -a solo
           muestra directorios; sin -s muestra todos los subdirectorios.
           Para ver los mayores consumidores se encadena con sort:
           du -h | sort -rh | head.
           Ojo: `du -sh *` no incluye los archivos ocultos; usa
           `du -sh .[!.]* *` o `du -h -d1`. Los errores de "Permiso denegado"
           se pueden ocultar con 2>/dev/null.
OPCIONES :
  -h          Tamaños legibles (K, M, G).
  -s          Solo el total de cada argumento (resumen).
  -a          Muestra también los archivos, no solo los directorios.
  -c          Añade una línea final con el total general.
  -d N        Profundidad máxima (--max-depth=N): du -h -d 1.
  -x          No cruza a otros sistemas de archivos.
  -k / -m     Tamaños en KiB / MiB.
  -b          Tamaño aparente en bytes.
  --apparent-size   Tamaño de los datos en lugar del espacio en disco.
  --exclude=PATRÓN  Ignora los archivos que casen con el patrón.
  -L          Sigue los enlaces simbólicos.
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