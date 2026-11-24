# 🛠️ Compilación

> **Requisito:** Este proyecto necesita un compilador con soporte para **C++23** (`g++` 13 o superior).

---

## ⚡ 1. Compilación automática con `make`

Para compilar y limpiar el proyecto de forma automatizada mediante el `Makefile`, utiliza los siguientes comandos:

| Comando | Descripción |
| :--- | :--- |
| `make` | Compila los archivos fuente y genera el ejecutable `copy`. |
| `make clean` | Elimina los archivos objeto (`.o`) y el ejecutable generado. |

```bash
make
```
---

## 🔧 2. Compilación manual con `g++`

Si prefieres compilar directamente desde la terminal sin usar `make`, puedes hacerlo de dos formas:

### Opción A: En un único paso
Compila y enlaza todos los archivos fuente simultáneamente:

```bash
g++ -std=c++23 -Wall -Wextra -Wpedantic main_copy.cc copy.cc -o copy
```

### Opción B: Por separado (unidades de traducción)
Genera primero los archivos objeto individuales y enlázalos al final:

```bash
# 1. Compilar cada archivo fuente por separado
g++ -std=c++23 -Wall -Wextra -Wpedantic -c copy.cc -o copy.o
g++ -std=c++23 -Wall -Wextra -Wpedantic -c main_copy.cc -o main_copy.o

# 2. Enlazar los objetos para obtener el ejecutable final
g++ main_copy.o copy.o -o copy
```