# MU Online Season 6 In-Browser Ecosystem (OpenMU + WebAssembly)

Este proyecto despliega un ecosistema completo para ejecutar el cliente de **MU Online Season 6 Episode 3** dentro del navegador web cliente mediante **WebAssembly (WASM)** y **WebGL 2.0**, respaldado por una arquitectura de microservicios contenerizada en **Docker**.

---

## 🏛️ Arquitectura General del Sistema

El sistema se compone de cuatro microservicios orquestados mediante Docker Compose:

1. **`mu-db` (PostgreSQL 15)**: Base de datos relacional para almacenamiento de cuentas, personajes, inventarios, estado del mundo y configuración de OpenMU.
2. **`mu-server` (OpenMU Core Engine)**: Servidor de juego desarrollado en .NET 8 / .NET 9. Maneja la lógica de Season 6 (cálculo de stats, inventarios, eventos, fórmulas de daño y autenticación).
3. **`mu-ws-proxy` (Proxy Node.js WebSocket-to-TCP)**: Middleware intermediario que recibe conexiones WebSocket desde el navegador cliente, reempaqueta los datagramas a sockets TCP puros de MU Online y reescribe al vuelo los paquetes `ConnectServer F4 03` (ConnectionInfo) para redirigir dinámicamente las conexiones del cliente.
4. **`mu-client-web` (Cliente Web Assembly + NGINX)**: Servidor web NGINX que sirve la aplicación web HTML5, el cliente compilado a WebAssembly (`client.js` y `client.wasm`) y los assets gráficos del juego (.bmd, .att, .ozj, .tga). Incluye cabeceras de aislamiento COOP y COEP para soporte de `SharedArrayBuffer`.

---

## 🔌 Mapeo de Puertos y Definición Técnica

A continuación se detallan los puertos utilizados por la infraestructura y su función específica:

| Puerto Interno | Puerto Host (Exposición) | Servicio | Protocolo | Descripción / Uso |
| :---: | :---: | :---: | :---: | :--- |
| **80 / 443** | `90 / 443` | `mu-client-web` | HTTP / HTTPS | Servidor Web NGINX (Expuesto en el puerto 90 del Host). Sirve el cliente en navegador HTML5/Canvas, los archivos `client.js`, `client.wasm` y los assets del juego. |
| **8080** | `8080` | `mu-ws-proxy` | WebSocket (WS/WSS) | Puerto de entrada del Proxy WebSocket. El cliente web se conecta aquí para transmitir los paquetes de red. |
| **44405** | `44405` | `mu-server` | TCP | **ConnectServer** de OpenMU. Recibe las solicitudes iniciales de lista de servidores y redirección. |
| **55901** | `55901` | `mu-server` | TCP | **GameServer (Server 1)** de OpenMU. Procesa el bucle principal del juego, mapas, combate e interacciones. |
| **8090** | `8090` | `mu-server` | HTTP | **OpenMU Admin Panel / Web API**. Panel de administración web del servidor OpenMU. |
| **5432** | `5432` | `mu-db` | TCP | Base de Datos **PostgreSQL 15**. Puerto interno para persistencia mediante Entity Framework Core. |

---

## ⚙️ Cabeceras de Aislamiento de Seguridad (COOP / COEP)

Para habilitar el uso de **`SharedArrayBuffer`** y multithreading dentro del motor WebAssembly en los navegadores modernos, la configuración de NGINX (`nginx/default.conf`) incluye obligatoriamente las siguientes cabeceras HTTP:

```nginx
add_header Cross-Origin-Opener-Policy "same-origin" always;
add_header Cross-Origin-Embedder-Policy "require-corp" always;
```

---

## 🛠️ Requisitos Previos

* **Docker Engine** 20.10+ y **Docker Compose** v2+
* **Git** (con soporte para submódulos si se realiza compilación local)
* Opcional (para desarrollo/compilación local de C++): **Emscripten SDK (`emsdk`)**, **CMake 3.25+** y **Node.js 20+**.

---

## 🚀 Despliegue y Puesta en Marcha

### 1. Iniciar el Ecosistema Completo con Docker

Para construir las imágenes y levantar todos los contenedores en segundo plano:

```bash
docker compose up -d
```

### 2. Verificar el Estado de los Servicios

```bash
docker compose ps
```

### 3. Acceso desde el Navegador

* **Cliente Web (Juego)**: [http://localhost:90](http://localhost:90)
* **Panel de Administración OpenMU**: [http://localhost:8090](http://localhost:8090)
* **Proxy WebSocket**: `ws://localhost:8080`

---

## 🛠️ Compilación del Cliente WebAssembly (`client.wasm`) y Persistencia en Disco

El servicio `mu-client-web` utiliza una compilación multietapa en Docker (`Dockerfile.client`) basada en la imagen oficial `emscripten/emsdk:latest`.
Los archivos compilados `client.wasm` y `client.js` se persisten en el directorio host `./public` mediante el volumen montado en Docker Compose, de modo que en ejecuciones posteriores no es necesario recompilar el cliente desde cero.

Si deseas compilar manualmente el cliente C++ a WebAssembly en tu máquina local:

```bash
# Otorgar permisos de ejecución al script de compilación
chmod +x scripts/build_wasm.sh

# Ejecutar la compilación WASM (requiere EMSDK instalado)
./scripts/build_wasm.sh
```

El script compilará el código C++ de **MuMain** y generará los artefactos finales en el directorio `public/`:
* `public/client.wasm`: Binario compilado del motor de juego C++.
* `public/client.js`: Código "glue" generado por Emscripten para la interfaz entre JavaScript/WebGL y WebAssembly.

---

## 🔁 Reescritura Dinámica de Paquetes (Proxy Network Layer)

Cuando un cliente WebAssembly selecciona un servidor dentro del juego, el ConnectServer de OpenMU responde con el paquete `C1 16 F4 03` (**ConnectionInfo**) conteniendo la IP y el puerto TCP nativo del GameServer (ej. `192.168.1.100:55901`).

El proxy Node.js (`proxy/packet-rewriter.js`) intercepta al vuelo este paquete y realiza lo siguiente:
1. Extrae el puerto destino del GameServer (`55901`).
2. Reemplaza la dirección IP y el puerto del paquete por la IP/puerto del **Proxy WebSocket** (`127.0.0.1:8080`).
3. Guarda un mapeo de la sesión del cliente para que la subsiguiente conexión WebSocket sea ruteada automáticamente hacia el puerto del GameServer correspondiente.
