/**
 * Universidad de La Laguna
 * Escuela Superior de Ingeniería y Tecnología
 * Grado en Ingeniería Informática
 * Asignatura: Sistemas Operativos
 * Curso: 2º
 * Autor: Giuseppe Fuentes Moreno
 * Correo: alu0101644080@ull.edu.es
 * Fecha: 11/11/2026
 * 
 * @file copy.cc
 * @brief Implementación de funciones para la copia robusta de archivos.
 * 
 * Contiene la definición de las funciones de entrada/salida a bajo nivel (POSIX)
 * para leer, escribir, y copiar archivos en bloques, gestionando señales de 
 * interrupción y comprobando atributos del sistema de archivos.
 */

#include "copy.h"

/**
 * @brief Genera un objeto std::unexpected que contiene un std::system_error.
 * 
 * Captura el valor actual de `errno` y lo empaqueta junto a un mensaje de 
 * contexto personalizado para facilitar el manejo estandarizado de errores en C++23.
 * 
 * @param context Cadena de texto descriptiva sobre dónde o por qué ocurrió el error.
 * @return std::unexpected<std::system_error> Objeto inesperado con el código de error.
 */
std::unexpected<std::system_error> error_system(std::string context) {
  return std::unexpected(std::system_error(errno, std::system_category(), std::move(context)));
}


#include <cerrno>

/**
 * @brief Valida los argumentos de la línea de comandos para el programa de copia.
 * 
 * Realiza comprobaciones de seguridad críticas antes de iniciar la copia:
 * 1. Verifica que se reciban exactamente 3 argumentos (ejecutable, origen, destino).
 * 2. Comprueba que el origen exista y sea un archivo regular (no un directorio).
 * 
 * @param argc Número de argumentos pasados al programa (incluyendo el ejecutable).
 * @param argv Array de punteros a las cadenas de texto con los argumentos.
 * @return std::expected<bool, std::system_error> true si los argumentos son válidos, 
 *         o un error del sistema si alguna validación de seguridad falla.
 */
std::expected<void, std::system_error> check_arg(int argc, const char* argv[]) {
    // Comprobar número de argumentos.
    if (argc != 3) {
        errno = EINVAL; 
        return error_system("Uso incorrecto. Formato esperado: ./copy <ruta_origen> <ruta_destino>");
    }

    std::string src_path = argv[1];
    struct stat st_src;

    // Comprobar que el origen existe.
    if (stat(src_path.c_str(), &st_src) == -1) {
        return error_system("El archivo de origen no existe o no es accesible.");
    }

    // Comprobar que el origen es un directorio.
    if (S_ISDIR(st_src.st_mode)) {
        errno = EISDIR; 
        return error_system("El origen es un directorio. Solo se pueden copiar archivos regulares.");
    }

    return {};
}

/**
 * @brief Comprueba si la ruta especificada corresponde a un directorio.
 * 
 * Utiliza la llamada al sistema stat() y la macro S_ISDIR para determinar
 * la naturaleza del archivo apuntado por la ruta.
 * 
 * @param src_path Ruta en el sistema de archivos a evaluar.
 * @return std::expected<bool, std::system_error> true si es un directorio, 
 *         false si es otro tipo de archivo, o un error del sistema si stat() falla.
 */
std::expected<bool, std::system_error> is_directory(const std::string& src_path) {
  struct stat st;
  std::expected<bool, std::system_error> condicion{true};

  if (stat(src_path.c_str(), &st) == -1) {
    return error_system("Error al acceder a los atributos del archivo.");
  } else {
    if (!S_ISDIR(st.st_mode)) {
      condicion = false;
    }
  }
  return condicion;
}

/**
 * @brief Determina si dos rutas apuntan físicamente al mismo archivo.
 * 
 * Compara el ID del dispositivo (st_dev) y el número de inodo (st_ino) de ambos 
 * archivos mediante la llamada stat() para evitar que un archivo se copie sobre sí mismo.
 * Si el archivo de destino no existe, asume de forma segura que no son el mismo.
 * 
 * @param src_path Ruta del archivo de origen.
 * @param dest_path Ruta del archivo de destino.
 * @return std::expected<void, std::system_error> Error si son idénticos o si hay un fallo real de lectura.
 */
std::expected<void, std::system_error> is_same_file(const std::string& src_path, const std::string& dest_path) {
    struct stat st_src;
    struct stat st_dest;

    if (stat(src_path.c_str(), &st_src) == -1) {
        return error_system("Error al acceder a los atributos del archivo origen.");
    }

    if (stat(dest_path.c_str(), &st_dest) == -1) {
        if (errno == ENOENT) {
            return {}; // El destino no existe, vía libre para copiar.
        }
        return error_system("Error al acceder a los atributos del archivo destino.");
    }

    if (st_src.st_dev == st_dest.st_dev && st_src.st_ino == st_dest.st_ino) {
        errno = EINVAL;
        return error_system("Ambos archivos son idénticos. Se aborta para evitar auto-sobrescritura.");
    }
    
    return {};
}

/**
 * @brief Lee datos de un descriptor de archivo de forma segura y robusta.
 * 
 * Maneja lecturas parciales e interrupciones por señales (EINTR). Redimensiona
 * dinámicamente el búfer para ajustarse a los bytes reales leídos al final del ciclo.
 * 
 * @param fd Descriptor de archivo abierto en modo lectura.
 * @param buffer Vector de bytes donde se almacenarán los datos leídos.
 * @param bytes_needed Cantidad máxima de bytes a leer en este bloque (por defecto 128 KiB).
 * @return true Si la lectura finalizó correctamente (incluso si se llegó al EOF).
 * @return false Si ocurrió un error crítico de I/O.
 */
bool read_data(int fd, std::vector<uint8_t>& buffer, size_t bytes_needed = 131072) {
    ssize_t bytes_read;
    size_t total_read{0};
    buffer.resize(bytes_needed);

    while (total_read < bytes_needed) {
        bytes_read = read(fd, buffer.data() + total_read, bytes_needed - total_read);

        if (bytes_read == -1) {
            if (errno == EINTR) continue;
            return false;
        } else if (bytes_read == 0) {
            break; // EOF
        }
        total_read += static_cast<size_t>(bytes_read);
    }
    buffer.resize(total_read);
    return true;
}

/**
 * @brief Escribe un bloque de datos en un descriptor de archivo de forma robusta.
 * 
 * Asegura que la totalidad del búfer se escriba en el disco, gestionando 
 * escrituras parciales del sistema operativo e interrupciones (EINTR).
 * 
 * @param fd Descriptor de archivo abierto en modo escritura.
 * @param buffer Vector constante de bytes que contiene los datos a escribir.
 * @return true Si todos los bytes se escribieron exitosamente.
 * @return false Si ocurrió un error crítico (ej. disco lleno o fallo de hardware).
 */
bool write_data(int fd, const std::vector<uint8_t>& buffer) {
    ssize_t bytes_write;
    size_t total_write{0};

    while (total_write < buffer.size()) {
        bytes_write = write(fd, buffer.data() + total_write, buffer.size() - total_write);

        if (bytes_write == -1) {
            if (errno == EINTR) continue;
            return false; 
        } else if (bytes_write == 0) {
            break;
        }
        total_write += static_cast<size_t>(bytes_write);
    }
    return true;
}

/**
 * @brief Copia el contenido de un archivo a otro utilizando bloques de memoria.
 * 
 * Orquesta la apertura segura de archivos, la gestión temporal de la máscara
 * de permisos (umask) para el archivo de destino, el ciclo de lectura-escritura 
 * por bloques y el cierre final de descriptores.
 * 
 * @param src_path Ruta del archivo de origen a copiar.
 * @param dest_path Ruta del archivo de destino donde se escribirá la copia.
 * @param dst_perms Permisos POSIX base con los que se creará el destino (por defecto 0644).
 * @return std::expected<void, std::system_error> Void en caso de éxito, 
 *         o un error del sistema si alguna fase (apertura, I/O, cierre) falla.
 */
std::expected<void, std::system_error> copy_file(const std::string& src_path, const std::string& dest_path, mode_t dst_perms = 0644) {
    int fd_src = open(src_path.c_str(), O_RDONLY);
    if (fd_src == -1) {
        return error_system("Error abriendo el archivo origen.");
    }

    mode_t umask_original = umask(0);
    int fd_dest = open(dest_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, dst_perms);
    umask(umask_original);

    if (fd_dest == -1) {
        close(fd_src);
        return error_system("Error creando o abriendo el archivo destino.");
    }

    std::vector<uint8_t> buffer;
    std::expected<void, std::system_error> resultado = {};

    while (true) {
        if (!read_data(fd_src, buffer)) {
            resultado = error_system("Error de Lectura.");
            break;
        }

        if (buffer.empty()) {
            break; 
        }

        if (!write_data(fd_dest, buffer)) {
            resultado = error_system("Error de Escritura.");
            break;
        }
    }

    int error_src = close(fd_src);
    int error_dest = close(fd_dest);

    if (resultado.has_value() && (error_src == -1 || error_dest == -1)) {
        return error_system("Error al cerrar los descriptores de los archivos.");
    }

    return resultado;
}