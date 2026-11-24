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
 * @file main_copy.cc
 * @brief Programa principal de la utilidad de copia de archivos.
 * 
 * Este archivo contiene la función principal que procesa los argumentos de 
 * la línea de comandos, orquesta las validaciones de seguridad de las rutas 
 * origen y destino, y ejecuta la función de copia a bajo nivel, gestionando 
 * y mostrando los posibles errores del sistema.
 */

#include "copy.h"


int protected_main(int argc, char* argv[]) {
  // 1. Validar argumentos
  if (!check_args(argc, argv)) {
    return EXIT_FAILURE;
  }

  std::string ruta_origen{argv[1]};
  std::string ruta_destino{argv[2]};

  // 2. Ajustar la ruta si el destino es un directorio
  if (is_directory(ruta_destino)) {
    std::filesystem::path destino{ruta_destino};
    destino /= std::filesystem::path{ruta_origen}.filename();
    ruta_destino = destino.string();
  }

  // 3. Comprobar identidad de los archivos para evitar auto-sobrescritura
  if (is_same_file(ruta_origen, ruta_destino)) {
    std::cerr << std::format("{}: ORIGEN y DESTINO son el mismo archivo\n", argv[0]);
    return EXIT_FAILURE;
  }

  // 4. Ejecutar la copia real
  auto copy_res = copy_file(ruta_origen, ruta_destino);
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