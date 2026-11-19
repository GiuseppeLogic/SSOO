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



std::unexpected<std::system_error> system_error_from_errno(std::string context) {
  // Captura inmediatamente el valor actual de errno (que guarda el código numérico del
  // último fallo en una llamada al sistema) y lo asocia con std::system_category() para
  // que el sistema operativo traduzca ese número a texto legible (ej. "Permission denied").
  return std::unexpected(
      std::system_error(errno, std::system_category(), std::move(context)));
}

bool check_args(int argc, char* argv[]) {
  if (argc != 3) {
    std::cerr << std::format("{}: se deben indicar los archivos ORIGEN y DESTINO\n", argv[0]);
    return false;
  }
  return true;
}

bool is_directory(const std::string& path) {
  struct stat st{}; // Estructura inicializada a cero donde el núcleo volcará los metadatos

  // stat() consulta los metadatos del inodo asociado a 'path'.
  // Si retorna -1 (por ejemplo, ENOENT si el archivo de destino todavía no existe),
  // no es un error fatal aquí: simplemente significa que no es un directorio existente.
  if (stat(path.c_str(), &st) == -1) {
    return false;
  }

  // st.st_mode contiene tanto el tipo de archivo como sus permisos.
  // La macro S_ISDIR aplica la máscara S_IFMT para comprobar si los bits de tipo
  // corresponden a un directorio.
  return S_ISDIR(st.st_mode);
}

bool is_same_file(const std::string& src_path, const std::string& dest_path) {
  struct stat st_src{};
  struct stat st_dest{};

  // Obtenemos los metadatos del origen. Si falla (ej. no existe), devolvemos false
  // para que sea copy_file() quien informe del error real al intentar abrirlo.
  if (stat(src_path.c_str(), &st_src) == -1) {
    return false;
  }

  // Obtenemos los metadatos del destino ya resuelto. Si aún no existe (ENOENT),
  // es físicamente imposible que sea el mismo archivo que el origen.
  if (stat(dest_path.c_str(), &st_dest) == -1) {
    return false;
  }

  // En POSIX, un archivo físico queda identificado de forma unívoca por el par:
  // - st_dev: identificador del dispositivo o sistema de archivos donde reside.
  // - st_ino: número de inodo dentro de ese dispositivo.
  // Comparar ambos detecta enlaces duros, rutas relativas ("./a" vs "a") o copias
  // dentro del directorio actual ("copy testfile.dat .").
  return (st_src.st_dev == st_dest.st_dev) && (st_src.st_ino == st_dest.st_ino);
}

bool read_data(int fd, std::vector<uint8_t>& buffer, std::size_t bytes_needed) {
  std::size_t total_read{0};
  // Reservamos espacio en el vector para recibir hasta 'bytes_needed' (128 KiB).
  buffer.resize(bytes_needed);

  // read() no garantiza leer todos los bytes solicitados en una sola llamada
  // (puede leer menos si hay interrupciones de señales o limitaciones del sistema).
  // Por eso iteramos hasta llenar el bloque o alcanzar el fin de archivo (EOF).
  while (total_read < bytes_needed) {
    // Avanzamos el puntero destino (buffer.data() + total_read) y restamos los bytes
    // que ya tenemos para no sobrescribir lo leído en iteraciones anteriores.
    ssize_t bytes_read = read(fd, buffer.data() + total_read, bytes_needed - total_read);

    if (bytes_read == -1) {
      // Si la llamada fue interrumpida por una señal antes de leer nada (EINTR),
      // no es un fallo real de E/S: reintentamos la lectura.
      if (errno == EINTR) {
        continue;
      }
      return false; // Error real de lectura (ej. EACCES, EIO)
    }

    if (bytes_read == 0) {
      // read() devuelve 0 cuando se alcanza el End-Of-File (EOF): no quedan más datos.
      break;
    }

    // Convertimos ssize_t (con signo) a size_t (sin signo) tras comprobar que > 0.
    total_read += static_cast<std::size_t>(bytes_read);
  }

  // Ajustamos el tamaño del vector al número exacto de bytes válidos leídos.
  // En la última lectura del archivo, total_read será menor que 128 KiB (o 0 en EOF).
  buffer.resize(total_read);
  return true;
}

bool write_data(int fd, const std::vector<uint8_t>& buffer) {
  std::size_t total_written{0};

  // Al igual que read(), write() puede escribir menos bytes de los solicitados
  // (escritura parcial). Iteramos hasta volcar el vector completo.
  while (total_written < buffer.size()) {
    ssize_t bytes_written = write(
        fd, buffer.data() + total_written, buffer.size() - total_written);

    if (bytes_written == -1) {
      if (errno == EINTR) {
        continue; // Interrupción por señal: reintentamos escribir el resto
      }
      return false; // Error real de escritura (ej. ENOSPC si no queda espacio en disco)
    }

    if (bytes_written == 0) {
      // Caso anómalo donde write() no avanza ni fija errno; asignamos EIO por seguridad.
      errno = EIO;
      return false;
    }

    total_written += static_cast<std::size_t>(bytes_written);
  }

  return true;
}

std::expected<size_t,std::system_error> get_file_size(const std::string& file_path){
  struct stat st;
  if (stat(file_path.c_str(), &st) == -1) {
    return system_error_from_errno(std::format("Error al acceder a los metadatos de '{}'", file_path));
  }
  
  return static_cast<std::size_t>(st.st_size);
}


std::expected<void, std::system_error> copy_file(
    const std::string& src_path,
    const std::string& dest_path,
    mode_t dst_perms) {
  // 1. Abrir el archivo de origen en modo solo lectura (O_RDONLY).
  // No se pasa tercer argumento (mode) porque no estamos creando ningún archivo.
  int fd_src = open(src_path.c_str(), O_RDONLY);
  if (fd_src == -1) {
    return system_error_from_errno("error al abrir el archivo de origen");
  }

  // 2. Abrir o crear el archivo de destino:
  // - O_WRONLY: solo escritura.
  // - O_CREAT: lo crea si no existe (requiere pasar 'dst_perms' como 3er argumento).
  // - O_TRUNC: si ya existía, vacía su contenido a 0 bytes antes de escribir.
  // Los permisos finales serán (dst_perms & ~umask) aplicados automáticamente por el núcleo.
  int fd_dest = open(dest_path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, dst_perms);
  if (fd_dest == -1) {
    auto error = system_error_from_errno("error al abrir el archivo de destino");
    close(fd_src);
    return error;
  }

  // 3. Bucle principal de copia por bloques de 128 KiB.
  std::vector<uint8_t> buffer;
  std::expected<void, std::system_error> resultado = {};

  auto size{get_file_size(src_path)};

  if (!size.has_value()) {
    return system_error_from_errno(std::format("Error al obtener el tamaño de '{}'", src_path));
  }

  size_t size_src{size.value()};
  int iteracion{1};
  
  while (true) {
    std::cout << "Tamaño del archivo origen por copiar en la iteración " << iteracion << " : " << size_src << "\n";

    // Leemos hasta 128 KiB del origen.
    if (!read_data(fd_src, buffer)) {
      resultado = system_error_from_errno("error al leer el archivo de origen");
      break;
    }

    // Si el vector quedó vacío tras read_data(), hemos llegado al EOF: copia terminada.
    if (buffer.empty()) {
      break;
    }

    size_src -= buffer.size();

    // Escribimos en el destino los bytes exactos que se acaban de leer.
    if (!write_data(fd_dest, buffer)) {
      resultado = system_error_from_errno("error al escribir el archivo de destino");
      break;
    }

    ++iteracion;
  }

  if (!resultado.has_value()) {
    close(fd_src);
    close(fd_dest);
    return resultado;
  }

  // 4. Liberación de recursos: cerramos siempre ambos descriptores de archivo,
  // tanto si la copia terminó con éxito como si se interrumpió por un error de E/S.
  int close_src_res = close(fd_src);
  int close_dest_res = close(fd_dest);

  // Solo informamos de un fallo al cerrar si no había ocurrido ya un error previo
  // en la lectura o escritura, para no ocultar el error principal.
  if (close_src_res == -1 || close_dest_res == -1) {
    return system_error_from_errno("error al cerrar los archivos");
  }

  return resultado;
}


