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

int main(int argc, char* argv[]) {
    // 1. Validar argumentos
    auto arg_check = check_arg(argc, argv);
    if (!arg_check.has_value()) {
        std::system_error error = arg_check.error(); 
        std::cerr << std::format("Código de Error ({}): {}\n", error.code().value(), error.what());
        return EXIT_FAILURE; 
    }

    // 2. Comprobar si el destino es un directorio
    auto dir_check = is_directory(std::string{argv[2]});
    if (!dir_check.has_value()) {
        std::system_error error = dir_check.error(); 
        std::cerr << std::format("Código de Error ({}): {}\n", error.code().value(), error.what());
        return EXIT_FAILURE; 
    }

    std::string ruta_origen{argv[1]};
    std::string ruta_destino{argv[2]};

    // 3. Ajustar la ruta si el destino es un directorio
    if (dir_check.value()) {
        std::filesystem::path origen{argv[1]};
        std::filesystem::path destino{argv[2]};
        destino /= origen.filename(); 
        ruta_destino = destino.string();
    }
    
    // 4. Comprobar identidad de los archivos para evitar auto-sobrescritura
    auto same_check = is_same_file(ruta_origen, ruta_destino);
    if (!same_check.has_value()) {
        std::system_error error = same_check.error(); 
        std::cerr << std::format("Código de Error ({}): {}\n", error.code().value(), error.what());
        return EXIT_FAILURE; 
    }

    // 5. Ejecutar la copia real
    auto copy_res = copy_file(ruta_origen, ruta_destino,0644);
    if (!copy_res.has_value()) {
        std::system_error error = copy_res.error(); 
        std::cerr << std::format("Código de Error ({}): {}\n", error.code().value(), error.what());
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}