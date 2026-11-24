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
 * @brief Programa principal de la utilidad concurrente de copia de archivos.
 * 
 * Este archivo contiene la función principal que bloquea las señales antes de crear
 * hilos, procesa los argumentos y opciones de compresión, valida todas las rutas de
 * origen y destino, prepara la estructura de progreso compartida y lanza el hilo de
 * atención síncrona de señales junto al hilo trabajador de copia.
 */

#include "copy.h"

int protected_main(int argc, char* argv[]) {
  // 1. Bloquear SIGPIPE desde el inicio del programa (no se añade al conjunto de sigtimedwait)
  auto sigpipe_res = block_sigpipe();
  if (!sigpipe_res.has_value()) {
    std::cerr << std::format("{}: {}\n", argv[0], sigpipe_res.error().what());
    return EXIT_FAILURE;
  }

  // 2. Analizar opciones y argumentos de la línea de comandos
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
    }
    print_usage(argv[0]);
    return EXIT_FAILURE;
  }

  Options options = arguments_result.value();

  // 3. Si hay múltiples archivos de origen, DESTINO debe ser un directorio existente
  if (options.src_paths.size() > 1 && !is_directory(options.dest_path)) {
    std::cerr << std::format("{}: DESTINO debe ser un directorio\n", argv[0]);
    return EXIT_FAILURE;
  }

  // 4. Si se pidió compresión, localizar el ejecutable en PATH antes de empezar
  std::string compression_path;
  if (options.compression != Options::CompressionType::NONE) {
    std::string comando = get_compression_command(options.compression);
    auto found = find_command(comando);
    if (!found.has_value()) {
      std::cerr << std::format("{}: error: {} no está instalado\n", argv[0], comando);
      return EXIT_FAILURE;
    }
    compression_path = std::move(found.value());
  }

  // 5. Preparar el vector de progreso con su tamaño definitivo y validar rutas
  std::vector<CopyProgress> progress(options.src_paths.size());
  for (std::size_t i = 0; i < options.src_paths.size(); ++i) {
    const std::string& src = options.src_paths[i];
    std::string dest = make_dest_path(src, options);

    if (is_same_file(src, dest)) {
      std::cerr << std::format("{}: {} y {} son el mismo archivo\n", argv[0], src, dest);
      return EXIT_FAILURE;
    }

    progress[i].src_path = src;
    progress[i].dest_path = std::move(dest);
    progress[i].total_bytes = get_file_size(src);
  }

  // 6. Bloquear SIGINT, SIGTERM y SIGUSR1 antes de crear ningún hilo
  auto signal_set_res = block_signals();
  if (!signal_set_res.has_value()) {
    std::cerr << std::format("{}: {}\n", argv[0], signal_set_res.error().what());
    return EXIT_FAILURE;
  }
  sigset_t signal_set = signal_set_res.value();

  // 7. Lanzar el hilo de señales y, en un ámbito interno, el hilo de copia
  std::stop_source copy_stop;
  bool copy_failed{false};

  std::jthread signal_thread(
      wait_for_signals, argv[0], signal_set, copy_stop, std::cref(progress));

  {
    std::jthread copy_thread(
        copy_worker, argv[0], std::cref(options), std::cref(compression_path),
        std::ref(progress), std::ref(copy_failed), copy_stop.get_token());
  }  // El destructor de copy_thread espera aquí a que termine toda la copia

  if (copy_failed) {
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
  // Al salir de protected_main(), el destructor de signal_thread pide su parada y lo espera.
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