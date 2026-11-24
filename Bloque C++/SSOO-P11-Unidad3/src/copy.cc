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
 * @file copy.cc
 * @brief Implementación de funciones para la copia concurrente y cancelable de archivos.
 * 
 * Contiene la definición de las funciones de análisis de argumentos, manejo síncrono
 * de señales (pthread_sigmask, sigtimedwait), operaciones POSIX de bajo nivel,
 * ejecución de compresores externos mediante tuberías y cancelación cooperativa con
 * std::stop_token y unlink().
 */

#include "copy.h"

std::unexpected<std::system_error> system_error_from_errno(std::string context) {
  return std::unexpected(
      std::system_error(errno, std::system_category(), std::move(context)));
}

void print_usage(std::string_view program_name) {
  std::cerr << std::format("uso: {} [-z | -j | -x] ORIGEN... DESTINO\n", program_name);
}

std::expected<Options, ParseArgsError> parse_arguments(int argc, char* argv[]) {
  Options options;
  optind = 1;

  for (int opt; (opt = getopt(argc, argv, ":zjx")) != -1;) {
    switch (opt) {
      case 'z':
        if (options.compression != Options::CompressionType::NONE) {
          return std::unexpected(ParseArgsError::multiple_compression_options);
        }
        options.compression = Options::CompressionType::GZIP;
        break;
      case 'j':
        if (options.compression != Options::CompressionType::NONE) {
          return std::unexpected(ParseArgsError::multiple_compression_options);
        }
        options.compression = Options::CompressionType::BZIP2;
        break;
      case 'x':
        if (options.compression != Options::CompressionType::NONE) {
          return std::unexpected(ParseArgsError::multiple_compression_options);
        }
        options.compression = Options::CompressionType::XZ;
        break;
      case '?':
      default:
        return std::unexpected(ParseArgsError::unknown_option);
    }
  }

  // Se necesitan al menos un ORIGEN y un DESTINO (2 argumentos posicionales).
  int positional_args = argc - optind;
  if (positional_args < 2) {
    return std::unexpected(ParseArgsError::missing_arguments);
  }

  // Todos los argumentos posicionales salvo el último son rutas de origen.
  options.src_paths.reserve(static_cast<std::size_t>(positional_args - 1));
  for (int i = optind; i < argc - 1; ++i) {
    options.src_paths.emplace_back(argv[i]);
  }
  options.dest_path = argv[argc - 1];

  return options;
}

std::optional<std::string> get_environment_variable(const std::string& name) {
  char* value = std::getenv(name.c_str());
  if (value != nullptr) {
    return std::string(value);
  }
  return std::nullopt;
}

std::string get_compression_command(Options::CompressionType compression) {
  switch (compression) {
    case Options::CompressionType::GZIP:
      return "gzip";
    case Options::CompressionType::BZIP2:
      return "bzip2";
    case Options::CompressionType::XZ:
      return "xz";
    case Options::CompressionType::NONE:
    default:
      return "";
  }
}

std::optional<std::string> find_command(std::string_view command) {
  if (command.empty()) {
    return std::nullopt;
  }

  auto path_env = get_environment_variable("PATH");
  if (!path_env.has_value()) {
    return std::nullopt;
  }

  std::string_view path_view{path_env.value()};
  std::size_t start{0};

  while (true) {
    std::size_t end = path_view.find(':', start);
    std::string_view dir = (end == std::string_view::npos)
                               ? path_view.substr(start)
                               : path_view.substr(start, end - start);

    std::filesystem::path candidate{dir.empty() ? "." : dir};
    candidate /= command;
    std::string candidate_str = candidate.string();

    if (access(candidate_str.c_str(), X_OK) == 0) {
      return candidate_str;
    }

    if (end == std::string_view::npos) {
      break;
    }
    start = end + 1;
  }

  return std::nullopt;
}

std::string get_compression_extension(Options::CompressionType compression) {
  switch (compression) {
    case Options::CompressionType::GZIP:
      return ".gz";
    case Options::CompressionType::BZIP2:
      return ".bz2";
    case Options::CompressionType::XZ:
      return ".xz";
    case Options::CompressionType::NONE:
    default:
      return "";
  }
}

std::string make_dest_path(std::string_view src_path, const Options& options) {
  std::string result = options.dest_path;
  if (is_directory(result)) {
    std::filesystem::path destino{result};
    destino /= std::filesystem::path{src_path}.filename();
    result = destino.string();
  }
  result += get_compression_extension(options.compression);
  return result;
}

std::uintmax_t get_file_size(const std::string& file_path) {
  struct stat st{};
  if (stat(file_path.c_str(), &st) == -1) {
    return 0;
  }
  return static_cast<std::uintmax_t>(st.st_size);
}

std::expected<void, std::system_error> block_sigpipe() {
  sigset_t sigpipe_set;
  if (sigemptyset(&sigpipe_set) == -1 ||
      sigaddset(&sigpipe_set, SIGPIPE) == -1 ||
      sigprocmask(SIG_BLOCK, &sigpipe_set, nullptr) == -1) {
    return system_error_from_errno("error al bloquear la señal SIGPIPE");
  }
  return {};
}

std::expected<sigset_t, std::system_error> block_signals() {
  sigset_t signal_set;
  if (sigemptyset(&signal_set) == -1 ||
      sigaddset(&signal_set, SIGINT) == -1 ||
      sigaddset(&signal_set, SIGTERM) == -1 ||
      sigaddset(&signal_set, SIGUSR1) == -1) {
    return system_error_from_errno("error al preparar el conjunto de señales");
  }

  // pthread_sigmask() devuelve directamente el código de error, no modifica errno.
  int error = pthread_sigmask(SIG_BLOCK, &signal_set, nullptr);
  if (error != 0) {
    return std::unexpected(std::system_error(
        error, std::system_category(), "no se pudieron bloquear las señales"));
  }

  return signal_set;
}

void wait_for_signals(
    std::stop_token stop_token,
    std::string_view program_name,
    sigset_t signal_set,
    std::stop_source copy_stop,
    const std::vector<CopyProgress>& progress) {
  try {
    while (!stop_token.stop_requested()) {
      siginfo_t signal_info{};
      // Plazo de 100 ms para revisar periódicamente si el jthread debe terminar.
      timespec timeout{.tv_sec = 0, .tv_nsec = 100'000'000};

      int signo = sigtimedwait(&signal_set, &signal_info, &timeout);
      if (signo == -1) {
        if (errno == EAGAIN || errno == EINTR) {
          continue;
        }
        std::cerr << std::format("{}: error al esperar señales: {}\n",
                                 program_name,
                                 std::system_error(errno, std::system_category()).what());
        break;
      }

      if (signo == SIGINT || signo == SIGTERM) {
        copy_stop.request_stop();
      } else if (signo == SIGUSR1) {
        // Componemos todas las líneas en un único buffer antes de imprimir
        // para evitar que se entremezclen con mensajes del hilo de copia.
        std::string report;
        for (const auto& item : progress) {
          std::uintmax_t total = item.total_bytes;
          std::uintmax_t copied = item.copied_bytes.load();
          std::uintmax_t percent = (total > 0) ? ((copied * 100) / total) : 0;
          report += std::format("{}: {}: {} de {} bytes ({}%)\n",
                                program_name, item.src_path, copied, total, percent);
        }
        std::cout << report << std::flush;
      }
    }
  } catch (const std::exception& e) {
    std::cerr << std::format("{}: error inesperado en el hilo de señales: {}\n",
                             program_name, e.what());
  } catch (...) {
    std::cerr << std::format("{}: error desconocido en el hilo de señales\n", program_name);
  }
}

bool is_directory(const std::string& path) {
  struct stat st{};

  if (stat(path.c_str(), &st) == -1) {
    return false;
  }

  return S_ISDIR(st.st_mode);
}

bool is_same_file(const std::string& src_path, const std::string& dest_path) {
  struct stat st_src{};
  struct stat st_dest{};

  if (stat(src_path.c_str(), &st_src) == -1) {
    return false;
  }

  if (stat(dest_path.c_str(), &st_dest) == -1) {
    return false;
  }

  return (st_src.st_dev == st_dest.st_dev) && (st_src.st_ino == st_dest.st_ino);
}

bool read_data(int fd, std::vector<uint8_t>& buffer, std::size_t bytes_needed) {
  std::size_t total_read{0};
  buffer.resize(bytes_needed);

  while (total_read < bytes_needed) {
    ssize_t bytes_read = read(fd, buffer.data() + total_read, bytes_needed - total_read);

    if (bytes_read == -1) {
      if (errno == EINTR) {
        continue;
      }
      return false;
    }

    if (bytes_read == 0) {
      break;
    }

    total_read += static_cast<std::size_t>(bytes_read);
  }

  buffer.resize(total_read);
  return true;
}

bool write_data(int fd, const std::vector<uint8_t>& buffer) {
  std::size_t total_written{0};

  while (total_written < buffer.size()) {
    ssize_t bytes_written = write(
        fd, buffer.data() + total_written, buffer.size() - total_written);

    if (bytes_written == -1) {
      if (errno == EINTR) {
        continue;
      }
      return false;
    }

    if (bytes_written == 0) {
      errno = EIO;
      return false;
    }

    total_written += static_cast<std::size_t>(bytes_written);
  }

  return true;
}

std::expected<void, std::system_error> copy_file(
    const std::string& src_path,
    const std::string& dest_path,
    CopyProgress& progress,
    std::stop_token stop_token,
    mode_t dst_perms) {
  // 1. Abrir el archivo de origen en modo solo lectura (O_RDONLY).
  int fd_src = open(src_path.c_str(), O_RDONLY);
  if (fd_src == -1) {
    return system_error_from_errno("error al abrir el archivo de origen");
  }

  // 2. Abrir o crear el archivo de destino.
  int fd_dest = open(dest_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, dst_perms);
  if (fd_dest == -1) {
    auto error = system_error_from_errno("error al abrir el archivo de destino");
    close(fd_src);
    return error;
  }

  // 3. Bucle principal de copia por bloques de 128 KiB con cancelación cooperativa.
  std::vector<uint8_t> buffer;
  std::expected<void, std::system_error> resultado = {};
  bool cancelled{false};

  while (true) {
    // Comprobamos la solicitud de parada antes de iniciar una nueva operación de E/S.
    if (stop_token.stop_requested()) {
      cancelled = true;
      break;
    }

    if (!read_data(fd_src, buffer)) {
      resultado = system_error_from_errno("error al leer el archivo de origen");
      break;
    }

    if (buffer.empty()) {
      break;
    }

    if (!write_data(fd_dest, buffer)) {
      resultado = system_error_from_errno("error al escribir el archivo de destino");
      break;
    }

    // Actualizamos el contador atómico una vez volcado el bloque completo.
    progress.copied_bytes += buffer.size();
  }

  // 4. Si la copia fue cancelada, cerramos descriptores, borramos el destino y retornamos ECANCELED.
  if (cancelled) {
    close(fd_src);
    close(fd_dest);
    unlink(dest_path.c_str());
    return std::unexpected(
        std::system_error(ECANCELED, std::system_category(), "copia cancelada"));
  }

  if (!resultado.has_value()) {
    close(fd_src);
    close(fd_dest);
    return resultado;
  }

  // 5. Liberación normal de recursos.
  int close_src_res = close(fd_src);
  int close_dest_res = close(fd_dest);

  if (close_src_res == -1 || close_dest_res == -1) {
    return system_error_from_errno("error al cerrar los archivos");
  }

  return resultado;
}

std::expected<void, std::system_error> copy_file_compressed(
    const std::string& src_path,
    const std::string& dest_path,
    const std::string& compression_path,
    CopyProgress& progress,
    std::stop_token stop_token,
    mode_t dst_perms) {
  // 1. Abrir el archivo de origen antes de crear la tubería o el proceso hijo.
  int fd_src = open(src_path.c_str(), O_RDONLY);
  if (fd_src == -1) {
    return system_error_from_errno("error al abrir el archivo de origen");
  }

  // 2. Crear la tubería anónima: pipe_fds[0] lectura (hijo), pipe_fds[1] escritura (padre).
  int pipe_fds[2];
  if (pipe(pipe_fds) == -1) {
    auto error = system_error_from_errno("error al crear la tubería");
    close(fd_src);
    return error;
  }

  std::fflush(nullptr);

  // 3. Crear el proceso hijo que ejecutará el comando de compresión.
  pid_t pid = fork();
  if (pid == -1) {
    auto error = system_error_from_errno("error al crear el proceso hijo");
    close(pipe_fds[0]);
    close(pipe_fds[1]);
    close(fd_src);
    return error;
  }

  if (pid == 0) {
    // --- CÓDIGO DEL PROCESO HIJO ---
    // En un programa multihilo, entre fork() y execv() solo deben llamarse funciones
    // async-signal-safe (sin reservar memoria ni bloquear mutex).
    close(fd_src);
    close(pipe_fds[1]);

    if (dup2(pipe_fds[0], STDIN_FILENO) == -1) {
      _exit(125);
    }
    close(pipe_fds[0]);

    int fd_dest = open(dest_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, dst_perms);
    if (fd_dest == -1) {
      _exit(125);
    }

    if (dup2(fd_dest, STDOUT_FILENO) == -1) {
      close(fd_dest);
      _exit(125);
    }
    close(fd_dest);

    // Restablecemos la máscara vacía para que el compresor no herede SIGINT,
    // SIGTERM, SIGUSR1 ni SIGPIPE bloqueadas.
    sigset_t empty_mask;
    sigemptyset(&empty_mask);
    if (sigprocmask(SIG_SETMASK, &empty_mask, nullptr) == -1) {
      _exit(125);
    }

    char* args[] = {
        const_cast<char*>(compression_path.c_str()),
        nullptr
    };
    execv(compression_path.c_str(), args);

    if (errno == ENOENT) {
      _exit(127);
    }
    if (errno == EACCES || errno == ENOEXEC) {
      _exit(126);
    }
    _exit(125);
  }

  // --- CÓDIGO DEL PROCESO PADRE ---
  close(pipe_fds[0]);

  std::vector<uint8_t> buffer;
  std::expected<void, std::system_error> resultado = {};
  bool cancelled{false};

  while (true) {
    // Comprobamos la cancelación antes de leer el siguiente bloque.
    if (stop_token.stop_requested()) {
      cancelled = true;
      break;
    }

    if (!read_data(fd_src, buffer)) {
      resultado = system_error_from_errno("error al leer el archivo de origen");
      break;
    }

    if (buffer.empty()) {
      break;
    }

    if (!write_data(pipe_fds[1], buffer)) {
      resultado = system_error_from_errno("error al escribir en la tubería");
      break;
    }

    // Actualizamos el progreso con los bytes leídos del origen y enviados al compresor.
    progress.copied_bytes += buffer.size();
  }

  // Cerramos origen y extremo de escritura de la tubería para enviar EOF al compresor.
  int close_src_res = close(fd_src);
  int close_pipe_res = close(pipe_fds[1]);

  // Esperamos siempre a que termine el proceso hijo antes de borrar el destino o salir.
  int status{0};
  pid_t wait_res{-1};
  do {
    wait_res = waitpid(pid, &status, 0);
  } while (wait_res == -1 && errno == EINTR);

  // Si la copia fue cancelada, eliminamos el archivo comprimido incompleto una vez
  // que el compresor ya ha finalizado y cerrado su salida.
  if (cancelled) {
    unlink(dest_path.c_str());
    return std::unexpected(
        std::system_error(ECANCELED, std::system_category(), "copia cancelada"));
  }

  if (wait_res == -1) {
    if (resultado.has_value()) {
      return system_error_from_errno("error al esperar al proceso de compresión");
    }
    return resultado;
  }

  if (!resultado.has_value()) {
    return resultado;
  }

  if (close_src_res == -1 || close_pipe_res == -1) {
    return system_error_from_errno("error al cerrar los descriptores");
  }

  if (WIFEXITED(status)) {
    int exit_code = WEXITSTATUS(status);
    if (exit_code == 0) {
      return {};
    }
    if (exit_code == 127) {
      return std::unexpected(std::system_error(
          ENOENT, std::system_category(),
          std::format("No se encontró el comando '{}'", compression_path)));
    }
    if (exit_code == 126) {
      return std::unexpected(std::system_error(
          EACCES, std::system_category(),
          std::format("No se pudo ejecutar el comando '{}'", compression_path)));
    }
    if (exit_code == 125) {
      return std::unexpected(std::system_error(
          EIO, std::system_category(),
          std::format("Error interno al preparar la ejecución de '{}'", compression_path)));
    }
    return std::unexpected(std::system_error(
        EIO, std::system_category(),
        std::format("El comando '{}' terminó con el código {}", compression_path, exit_code)));
  }

  if (WIFSIGNALED(status)) {
    int signal_num = WTERMSIG(status);
    return std::unexpected(std::system_error(
        EIO, std::system_category(),
        std::format("El comando '{}' terminó por la señal {}", compression_path, signal_num)));
  }

  return {};
}

void copy_worker(
    std::string_view program_name,
    const Options& options,
    const std::string& compression_path,
    std::vector<CopyProgress>& progress,
    bool& failed,
    std::stop_token stop_token) {
  try {
    for (auto& item : progress) {
      // Si se solicitó la cancelación justo entre archivo y archivo, detenemos el bucle
      // sin llegar a abrir ni truncar el siguiente archivo de destino.
      if (stop_token.stop_requested()) {
        std::cerr << std::format("{}: copia cancelada\n", program_name);
        failed = true;
        break;
      }

      std::expected<void, std::system_error> res = {};
      if (options.compression != Options::CompressionType::NONE) {
        res = copy_file_compressed(
            item.src_path, item.dest_path, compression_path, item, stop_token);
      } else {
        res = copy_file(item.src_path, item.dest_path, item, stop_token);
      }

      if (!res.has_value()) {
        failed = true;
        if (res.error().code() == std::errc::operation_canceled) {
          std::cerr << std::format("{}: copia cancelada, se ha eliminado {}\n",
                                   program_name, item.dest_path);
          break;
        }
        std::cerr << std::format("{}: error al copiar {}: {}\n",
                                 program_name, item.src_path, res.error().what());
      }
    }
  } catch (const std::exception& e) {
    failed = true;
    std::cerr << std::format("{}: error inesperado en el hilo de copia: {}\n",
                             program_name, e.what());
  } catch (...) {
    failed = true;
    std::cerr << std::format("{}: error desconocido en el hilo de copia\n", program_name);
  }
}


