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
 * @file copy.h
 * @brief Declaraciones de las funciones para la utilidad de copia de archivos.
 * 
 * Contiene los prototipos de las funciones encargadas de validar argumentos, 
 * comprobar los atributos del sistema de archivos y realizar operaciones de 
 * lectura y escritura a bajo nivel (POSIX) para copiar archivos por bloques.
 */

#ifndef SRC_COPY_H
#define SRC_COPY_H

#include <cerrno>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <exception>
#include <expected>
#include <fcntl.h>
#include <filesystem>
#include <format>
#include <iostream>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>
#include <system_error>
#include <unistd.h>
#include <utility>
#include <vector>

/**
 * @brief Genera un objeto std::unexpected con el código actual de errno.
 * 
 * Captura el valor de errno inmediatamente tras fallar una llamada al sistema
 * y lo empaqueta junto a un mensaje de contexto descriptivo.
 * 
 * @param context Mensaje descriptivo sobre la operación que falló.
 * @return std::unexpected<std::system_error> Objeto de error listo para propagarse.
 */
std::unexpected<std::system_error> system_error_from_errno(std::string context);

/**
 * @brief Comprueba los argumentos recibidos por línea de comandos.
 * 
 * Verifica que se hayan pasado exactamente dos argumentos adicionales al nombre
 * del programa (ORIGEN y DESTINO). En caso contrario, muestra el mensaje de
 * error correspondiente por la salida de error estándar.
 * 
 * @param argc Número total de argumentos pasados al programa.
 * @param argv Array de cadenas con los argumentos de la línea de comandos.
 * @return true Si los argumentos son válidos.
 * @return false Si el número de argumentos es incorrecto.
 */
bool check_args(int argc, char* argv[]);

/**
 * @brief Comprueba si la ruta especificada corresponde a un directorio.
 * 
 * Consulta los metadatos del archivo mediante stat() y evalúa su tipo con
 * la macro S_ISDIR. Si la ruta no existe o no es accesible, devuelve false.
 * 
 * @param path Ruta en el sistema de archivos a evaluar.
 * @return true Si la ruta existe y es un directorio.
 * @return false En caso contrario.
 */
bool is_directory(const std::string& path);

/**
 * @brief Determina si dos rutas apuntan físicamente al mismo archivo.
 * 
 * Compara el identificador de dispositivo (st_dev) y el número de inodo (st_ino)
 * obtenidos con stat() para evitar que un archivo se sobrescriba a sí mismo.
 * 
 * @param src_path Ruta del archivo de origen.
 * @param dest_path Ruta del archivo de destino ya resuelta.
 * @return true Si ambos archivos existen y comparten dispositivo e inodo.
 * @return false Si son archivos distintos o alguno aún no existe.
 */
bool is_same_file(const std::string& src_path, const std::string& dest_path);

/**
 * @brief Lee un bloque de datos de un descriptor de archivo de forma robusta.
 * 
 * Gestiona lecturas parciales e interrupciones por señales (EINTR) hasta
 * completar el tamaño solicitado o alcanzar el final del archivo (EOF),
 * ajustando el tamaño final del búfer a los bytes realmente leídos.
 * 
 * @param fd Descriptor de archivo abierto en modo lectura.
 * @param buffer Vector donde se almacenarán los bytes leídos.
 * @param bytes_needed Tamaño máximo del bloque a leer (por defecto 128 KiB).
 * @return true Si la lectura finalizó sin errores (incluyendo EOF).
 * @return false Si ocurrió un error de lectura en la llamada al sistema.
 */
bool read_data(int fd, std::vector<uint8_t>& buffer, std::size_t bytes_needed = 131072);

/**
 * @brief Escribe el contenido completo de un búfer en un descriptor de archivo.
 * 
 * Realiza escrituras en bucle para garantizar que se vuelcan todos los bytes
 * del vector, manejando escrituras parciales e interrupciones (EINTR).
 * 
 * @param fd Descriptor de archivo abierto en modo escritura.
 * @param buffer Vector constante con los datos a escribir.
 * @return true Si todos los bytes se escribieron correctamente.
 * @return false Si ocurrió un error durante la escritura.
 */
bool write_data(int fd, const std::vector<uint8_t>& buffer);

/**
 * @brief Copia el contenido de un archivo a otro mediante llamadas al sistema POSIX.
 * 
 * Abre el archivo de origen en solo lectura y crea o trunca el de destino con
 * los permisos indicados (modificados por la umask del proceso), transfiriendo
 * los datos en bloques de 128 KiB y cerrando los descriptores antes de retornar.
 * 
 * @param src_path Ruta del archivo de origen.
 * @param dest_path Ruta del archivo de destino.
 * @param dst_perms Permisos base para crear el destino (por defecto 0644).
 * @return std::expected<void, std::system_error> Vacío en caso de éxito, o el error
 *         del sistema producido durante la apertura, lectura, escritura o cierre.
 */
[[nodiscard]]
std::expected<void, std::system_error> copy_file(
    const std::string& src_path,
    const std::string& dest_path,
    mode_t dst_perms = 0644);

/**
 * @brief Obtiene el tamaño de un archivo.
 * 
 * @param file_path 
 * @return std::expected<size_t,std::system_error> 
 */
std::expected<size_t,std::system_error> get_file_size(const std::string& file_path);

#endif