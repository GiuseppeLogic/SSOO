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
 * @file main_copy.cc
 * @brief Programa principal de la utilidad de copia de archivos.
 * 
 * Este archivo contiene la función principal que bloquea SIGPIPE, procesa los
 * argumentos y opciones de compresión de la línea de comandos, verifica que el
 * compresor solicitado esté disponible, valida las rutas de origen y destino,
 * y ejecuta la copia directa o comprimida gestionando los errores del sistema.
 */

#include "copy.h"

int protected_main(int argc, char* argv[]) {
  // 1. Bloquear SIGPIPE desde el inicio del programa
  auto sigpipe_res = block_sigpipe();
  if (!sigpipe_res.has_value()) {
    std::cerr << std::format("{}: {}\n", argv[0], sigpipe_res.error().what());
    return EXIT_FAILURE;
  }

  // 2. Validar y analizar argumentos y opciones de compresión
  auto arguments_result = parse_arguments(argc, argv);
  if (!arguments_result.has_value()) {
    switch (arguments_result.error()) {
      case ParseArgsError::unknown_option:
        std::cerr << std::format("{}: error: opción desconocida\n", argv[0]);
        break;
      case ParseArgsError::multiple_compression_options:
        std::cerr << std::format("{}: error: solo se admite una opción de compresión\n", argv[0]);
        break;
      case ParseArgsError::missing_arguments:
        std::cerr << std::format("{}: se deben indicar los archivos ORIGEN y DESTINO\n", argv[0]);
        break;
      case ParseArgsError::too_many_arguments:
        std::cerr << std::format("{}: demasiados argumentos\n", argv[0]);
        break;
    }
    print_usage(argv[0]);
    return EXIT_FAILURE;
  }

  Options options = arguments_result.value();

  // 3. Si se pidió compresión, localizar el comando en PATH antes de empezar
  std::optional<std::string> compression_path;
  if (options.compression != Options::CompressionType::NONE) {
    std::string comando = get_compression_command(options.compression);
    compression_path = find_command(comando);
    if (!compression_path.has_value()) {
      std::cerr << std::format("{}: error: {} no está instalado\n", argv[0], comando);
      return EXIT_FAILURE;
    }
  }

  // 4. Ajustar la ruta de destino si es un directorio y añadir la extensión de compresión
  if (is_directory(options.dest_path)) {
    std::filesystem::path destino{options.dest_path};
    destino /= std::filesystem::path{options.src_path}.filename();
    options.dest_path = destino.string();
  }
  options.dest_path += get_compression_extension(options.compression);

  // 5. Comprobar identidad de los archivos para evitar auto-sobrescritura
  if (is_same_file(options.src_path, options.dest_path)) {
    std::cerr << std::format("{}: ORIGEN y DESTINO son el mismo archivo\n", argv[0]);
    return EXIT_FAILURE;
  }

  // 6. Ejecutar la copia (comprimida o directa)
  std::expected<void, std::system_error> copy_res = {};
  if (options.compression != Options::CompressionType::NONE) {
    copy_res = copy_file_compressed(
        options.src_path, options.dest_path, compression_path.value());
  } else {
    copy_res = copy_file(options.src_path, options.dest_path);
  }

  if (!copy_res.has_value()) {
    std::cerr << std::format("{}: {}\n", argv[0], copy_res.error().what());
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

int main(int argc, char* argv[]) {
  try {
    return protected_main(argc, argv);
  } catch (const std::system_error& e) {
    std::cerr << std::format("{}: error inesperado ({}): {}\n",
                             argv[0], e.code().value(), e.what());
  } catch (const std::exception& e) {
    std::cerr << std::format("{}: error inesperado: {}\n", argv[0], e.what());
  }
  return EXIT_FAILURE;
}
