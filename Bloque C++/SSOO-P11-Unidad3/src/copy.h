/**
 * Universidad de La Laguna
 * Escuela Superior de Ingeniería y Tecnología
 * Grado en Ingeniería Informática
 * Asignatura: Sistemas Operativos
 * Curso: 2º
 * Autor: Giuseppe Fuentes Moreno
 * Correo: alu0101644080@ull.edu.es
 * Fecha: 24/11/2026
 * 
 * @file copy.h
 * @brief Declaraciones de las funciones para la utilidad concurrente de copia de archivos.
 * 
 * Contiene los prototipos de las funciones encargadas de procesar múltiples archivos
 * de origen y opciones de compresión, gestionar señales de forma síncrona en un hilo
 * dedicado, realizar copias directas o comprimidas con cancelación cooperativa y
 * reportar el progreso en tiempo real.
 */

#ifndef SRC_COPY_H
#define SRC_COPY_H

#include <atomic>
#include <cerrno>
#include <csignal>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <exception>
#include <expected>
#include <fcntl.h>
#include <filesystem>
#include <format>
#include <functional>
#include <iostream>
#include <optional>
#include <stop_token>
#include <string>
#include <string_view>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <system_error>
#include <thread>
#include <unistd.h>
#include <utility>
#include <vector>

/**
 * @brief Configuración extraída de los argumentos de la línea de comandos.
 */
struct Options {
  enum class CompressionType {
    NONE,
    GZIP,
    BZIP2,
    XZ
  };

  CompressionType compression = CompressionType::NONE;
  std::vector<std::string> src_paths;
  std::string dest_path;
};

/**
 * @brief Posibles errores al analizar los argumentos de la línea de comandos.
 */
enum class ParseArgsError {
  unknown_option,
  multiple_compression_options,
  missing_arguments,
};

/**
 * @brief Estructura compartida entre hilos para consultar el progreso de cada copia.
 * 
 * Las rutas y el tamaño total se fijan antes de arrancar los hilos y solo se leen.
 * El contador de bytes copiados es atómico para evitar condiciones de carrera entre
 * el hilo de copia y el hilo de señales.
 */
struct CopyProgress {
  std::string src_path;
  std::string dest_path;
  std::uintmax_t total_bytes{0};
  std::atomic<std::uintmax_t> copied_bytes{0};
};

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
 * @brief Muestra por la salida de error estándar el modo de uso del programa.
 * 
 * @param program_name Nombre con el que se invocó el ejecutable (argv[0]).
 */
void print_usage(std::string_view program_name);

/**
 * @brief Analiza las opciones y argumentos de la línea de comandos.
 * 
 * Procesa mediante getopt() las opciones mutuamente excluyentes (-z, -j, -x)
 * y recoge uno o más archivos ORIGEN seguidos de la ruta DESTINO.
 * 
 * @param argc Número total de argumentos pasados al programa.
 * @param argv Array de cadenas con los argumentos de la línea de comandos.
 * @return std::expected<Options, ParseArgsError> Estructura Options válida o código de error.
 */
[[nodiscard]]
std::expected<Options, ParseArgsError> parse_arguments(int argc, char* argv[]);

/**
 * @brief Consulta el valor de una variable de entorno.
 * 
 * @param name Nombre de la variable de entorno.
 * @return std::optional<std::string> Valor de la variable o std::nullopt si no existe.
 */
std::optional<std::string> get_environment_variable(const std::string& name);

/**
 * @brief Devuelve el nombre del ejecutable asociado al formato de compresión.
 * 
 * @param compression Tipo de compresión seleccionado.
 * @return std::string Nombre del comando ("gzip", "bzip2", "xz" o "").
 */
std::string get_compression_command(Options::CompressionType compression);

/**
 * @brief Localiza la ruta absoluta de un comando ejecutable en PATH.
 * 
 * @param command Nombre del comando a buscar.
 * @return std::optional<std::string> Ruta absoluta ejecutable o std::nullopt si no se encuentra.
 */
std::optional<std::string> find_command(std::string_view command);

/**
 * @brief Devuelve la extensión de archivo correspondiente al formato de compresión.
 * 
 * @param compression Tipo de compresión seleccionado.
 * @return std::string Extensión (".gz", ".bz2", ".xz" o "").
 */
std::string get_compression_extension(Options::CompressionType compression);

/**
 * @brief Construye la ruta final del archivo de destino para un archivo de origen.
 * 
 * Si DESTINO es un directorio existente, añade el nombre base del archivo de origen
 * y, a continuación, concatena la extensión correspondiente al formato de compresión.
 * 
 * @param src_path Ruta del archivo de origen.
 * @param options Configuración del programa (ruta de destino base y tipo de compresión).
 * @return std::string Ruta definitiva del archivo de destino.
 */
std::string make_dest_path(std::string_view src_path, const Options& options);

/**
 * @brief Obtiene el tamaño en bytes de un archivo mediante stat().
 * 
 * Si stat() falla (por ejemplo, si el archivo no existe), devuelve 0 para que sea
 * la función de copia la que informe del error real al intentar abrirlo.
 * 
 * @param file_path Ruta del archivo a consultar.
 * @return std::uintmax_t Tamaño del archivo en bytes o 0 si no se pudo consultar.
 */
std::uintmax_t get_file_size(const std::string& file_path);

/**
 * @brief Bloquea la señal SIGPIPE en el hilo principal antes de crear hilos.
 * 
 * Evita que escribir en una tubería rota termine el proceso, haciendo que write()
 * retorne -1 con errno igual a EPIPE.
 * 
 * @return std::expected<void, std::system_error> Vacío en éxito o error del sistema.
 */
[[nodiscard]]
std::expected<void, std::system_error> block_sigpipe();

/**
 * @brief Bloquea las señales SIGINT, SIGTERM y SIGUSR1 mediante pthread_sigmask().
 * 
 * Debe llamarse antes de crear ningún hilo para que todos hereden esta máscara y
 * las señales puedan ser recogidas de forma síncrona por el hilo dedicado.
 * 
 * @return std::expected<sigset_t, std::system_error> Conjunto de señales bloqueadas o error.
 */
[[nodiscard]]
std::expected<sigset_t, std::system_error> block_signals();

/**
 * @brief Función principal del hilo dedicado a esperar y atender señales síncronamente.
 * 
 * Espera con sigtimedwait() en intervalos cortos para poder comprobar el stop_token
 * de su propio std::jthread. Ante SIGINT o SIGTERM solicita la cancelación de la copia;
 * ante SIGUSR1 imprime el progreso actual de todos los archivos.
 * 
 * @param stop_token Token de parada del propio hilo de señales.
 * @param program_name Nombre del ejecutable para prefijar los mensajes.
 * @param signal_set Conjunto de señales bloqueadas a esperar.
 * @param copy_stop Fuente de parada compartida para cancelar la copia en curso.
 * @param progress Vector constante con el estado de progreso de cada archivo.
 */
void wait_for_signals(
    std::stop_token stop_token,
    std::string_view program_name,
    sigset_t signal_set,
    std::stop_source copy_stop,
    const std::vector<CopyProgress>& progress);

/**
 * @brief Comprueba si la ruta especificada corresponde a un directorio.
 * 
 * @param path Ruta en el sistema de archivos a evaluar.
 * @return true Si la ruta existe y es un directorio.
 * @return false En caso contrario.
 */
bool is_directory(const std::string& path);

/**
 * @brief Determina si dos rutas apuntan físicamente al mismo archivo.
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
 * @param fd Descriptor de archivo abierto en modo escritura.
 * @param buffer Vector constante con los datos a escribir.
 * @return true Si todos los bytes se escribieron correctamente.
 * @return false Si ocurrió un error durante la escritura.
 */
bool write_data(int fd, const std::vector<uint8_t>& buffer);

/**
 * @brief Copia el contenido de un archivo a otro con soporte de progreso y cancelación.
 * 
 * Comprueba stop_token antes de leer cada bloque de 128 KiB. Si se solicita la
 * cancelación, cierra los descriptores, elimina el archivo incompleto con unlink()
 * y retorna un error con código ECANCELED.
 * 
 * @param src_path Ruta del archivo de origen.
 * @param dest_path Ruta del archivo de destino.
 * @param progress Estructura de progreso donde acumular los bytes escritos.
 * @param stop_token Token de cancelación cooperativa de la copia.
 * @param dst_perms Permisos base para crear el destino (por defecto 0644).
 * @return std::expected<void, std::system_error> Vacío en éxito o error del sistema.
 */
[[nodiscard]]
std::expected<void, std::system_error> copy_file(
    const std::string& src_path,
    const std::string& dest_path,
    CopyProgress& progress,
    std::stop_token stop_token,
    mode_t dst_perms = 0644);

/**
 * @brief Copia un archivo comprimiéndolo mediante un proceso hijo con soporte de cancelación.
 * 
 * Ante una solicitud de cancelación, deja de escribir en la tubería, cierra su extremo
 * de escritura para enviar EOF al compresor, espera con waitpid() y elimina el archivo
 * de destino resultante con unlink().
 * 
 * @param src_path Ruta del archivo de origen.
 * @param dest_path Ruta del archivo de destino (con la extensión de compresión).
 * @param compression_path Ruta absoluta del ejecutable del compresor.
 * @param progress Estructura de progreso donde acumular los bytes leídos del origen.
 * @param stop_token Token de cancelación cooperativa de la copia.
 * @param dst_perms Permisos base para crear el destino (por defecto 0644).
 * @return std::expected<void, std::system_error> Vacío en éxito o error del sistema.
 */
[[nodiscard]]
std::expected<void, std::system_error> copy_file_compressed(
    const std::string& src_path,
    const std::string& dest_path,
    const std::string& compression_path,
    CopyProgress& progress,
    std::stop_token stop_token,
    mode_t dst_perms = 0644);

/**
 * @brief Función principal del hilo encargado de copiar secuencialmente todos los archivos.
 * 
 * Recorre el vector de progreso y ejecuta copy_file() o copy_file_compressed(). Si un
 * archivo falla por un error de E/S, muestra el mensaje, marca failed = true y continúa
 * con el siguiente; si se detecta cancelación, informa y detiene todo el proceso.
 * 
 * @param program_name Nombre del ejecutable para prefijar los mensajes de error.
 * @param options Configuración de la línea de comandos.
 * @param compression_path Ruta del compresor (vacía si no hay compresión).
 * @param progress Vector con las rutas y contadores de cada archivo.
 * @param failed Bandera de salida que indica si alguna copia falló o fue cancelada.
 * @param stop_token Token de cancelación cooperativa.
 */
void copy_worker(
    std::string_view program_name,
    const Options& options,
    const std::string& compression_path,
    std::vector<CopyProgress>& progress,
    bool& failed,
    std::stop_token stop_token);

#endif