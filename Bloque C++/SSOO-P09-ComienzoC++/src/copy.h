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

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <filesystem>
#include <expected>
#include <system_error>
#include <string>
#include <fcntl.h>
#include <unistd.h>
#include <vector>
#include <iostream>
#include <format>
#include <cstdlib>

// Empaqueta el error actual del sistema (errno) en un objeto compatible con C++23.
std::unexpected<std::system_error> system_error_from_errno(std::string context);

// Comprueba mediante llamadas POSIX si la ruta indicada corresponde a una carpeta.
std::expected<bool,std::system_error> is_directory(const std::string& src_path);

// Verifica si dos rutas apuntan físicamente al mismo archivo (usando inodos) para evitar autodestrucción.
std::expected<void,std::system_error> is_same_file(const std::string& src_path,const std::string& dest_path);

// Valida que el número y tipo de argumentos pasados por la terminal sean correctos y seguros.
std::expected<void,std::system_error> check_arg(int argc, const char* argv[]);

// Extrae de forma robusta un bloque de datos (hasta 128 KiB) del archivo de origen hacia la RAM.
bool read_data(int fd, std::vector<uint8_t>& buffer, size_t bytes_needed = 131072);

// Vuelca de forma segura todo el contenido del bloque almacenado en la RAM al archivo de destino.
bool write_data(int fd, const std::vector<uint8_t>& buffer);

// Orquesta el proceso global: abre archivos, maneja la umask, llama al bucle de lectura/escritura y cierra los descriptores.
std::expected<void, std::system_error> copy_file(const std::string& src_path, const std::string& dest_path, mode_t dst_perms = 0644);

#endif