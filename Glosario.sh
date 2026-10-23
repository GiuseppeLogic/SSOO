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

ORDEN=(echo which cat type ls find less file cp ln mv rm mkdir chmod chgrp
       chown sort uniq cut grep head tail tr wc sed ps df lsof comm)

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
SINTAXIS : printf FORMATO [argumentos...]
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
  -atime -7        Leido hace menos de 7 días.
  -ctime -8        Modificado su contenido hace menos de 8 días.
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
TECLAS   :
  Espacio / b    Página siguiente / anterior
  j / k          Línea siguiente / anterior
  g / G          Principio / final del archivo
  /patrón        Busca hacia delante (?patrón hacia atrás); n / N siguiente / previa
  q              Salir
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
  -s   Crea un enlace simbólico en lugar de uno duro. Posible alternativa con cp -s ...
  -f   Sobrescribe el enlace si ya existe.
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
DETALLE  :  Un usuario normal solo puede cambiarlo si es el propietario y pertenece 
            al grupo de  destino; root puede cambiarlo siempre. Es equivalente a
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
  -A N / -B N / -C N   Muestra N líneas después / antes / alrededor.
  -q   Silencioso: solo devuelve el código de salida.
  -h / -H   Oculta / muestra el nombre de archivo.
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
  -P   Utiliza el formato POSIX para el resultado
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
  -t            Muestra solo los PID (modo terso, para usar con kill).
  -a            Combina los filtros con AND.
  ARCHIVO       Procesos que tienen abierto ese archivo.
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
  comm -13 <(sort a.txt) <(sort b.txt)    # líneas solo en b.txt
  comm -3 a_ordenado.txt b_ordenado.txt   # lo que difiere
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