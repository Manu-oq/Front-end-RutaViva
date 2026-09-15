# Ruta Viva — Cliente Flutter

Cliente multiplataforma de **Ruta Viva**, una plataforma de turismo inteligente desarrollada como trabajo de título. Permite explorar puntos de interés de La Araucanía, consultar su ubicación y detalle, guardar favoritos, crear itinerarios y recibir recomendaciones contextuales.

Este repositorio consume la API de [Back-end-RutaViva](https://github.com/Manu-oq/Back-end-RutaViva), construida con FastAPI, PostgreSQL, PostGIS y pgvector.

## Funcionalidades

- Registro, inicio de sesión y sesión persistente mediante JWT.
- Mapa interactivo, geolocalización y consulta de puntos de interés.
- Búsqueda geográfica y semántica de destinos.
- Detalle de POIs, favoritos, reseñas y carga de imágenes.
- Creación, edición, reordenamiento y visualización de itinerarios.
- Flujos diferenciados para turistas y emprendedores.
- Asistente conversacional para recomendaciones e itinerarios cuando el backend tiene proveedores de IA configurados.
- Estados de carga, errores recuperables, modo oscuro y diseño responsive.

## Stack

| Área | Tecnologías |
|---|---|
| Aplicación | Flutter, Dart |
| Estado y navegación | Riverpod, GoRouter |
| Red y persistencia | Dio, shared_preferences |
| Mapa y ubicación | flutter_map, geolocator, latlong2 |
| Interfaz | Material 3, Google Fonts, Shimmer |
| Calidad | flutter_lints, pruebas unitarias y de widgets |

## Vistas del producto

Las siguientes capturas se incorporarán al repositorio cuando estén disponibles. Guárdalas en `docs/images/` con estos nombres para enlazarlas directamente:

| Archivo | Contenido recomendado |
|---|---|
| `home.png` | Inicio autenticado con POIs o navegación principal visible. |
| `map.png` | Mapa con marcadores y categorías. |
| `itinerary.png` | Detalle de un itinerario generado o guardado. |

No es necesario capturar el chat si las claves de IA fueron revocadas: esas tres vistas comunican mejor el producto sin mostrar información sensible.

## Ejecución local en Linux

### Requisitos

- Flutter instalado y disponible en `PATH`.
- Backend de Ruta Viva ejecutándose en `http://127.0.0.1:8000`.

Primero levanta el backend siguiendo sus [instrucciones](https://github.com/Manu-oq/Back-end-RutaViva#ejecución-local). Luego, desde este repositorio:

```bash
flutter pub get
flutter run -d linux \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
  --dart-define=API_ORIGIN=http://127.0.0.1:8000
```

Para Android Emulator cambia ambos orígenes `127.0.0.1` por `10.0.2.2`:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
  --dart-define=API_ORIGIN=http://10.0.2.2:8000
```

La app también tiene valores locales por defecto, pero usar `--dart-define` deja explícita la conexión y evita problemas al cambiar de plataforma.

## Calidad

```bash
flutter analyze
flutter test
```

## Estructura

```text
lib/
├── core/       # red, rutas, tema, almacenamiento y widgets reutilizables
└── features/   # módulos por dominio: auth, mapa, chat, itinerarios, POIs, etc.
test/           # pruebas unitarias y de widgets
```

## Notas de demostración

Una base de datos nueva no incluye POIs ni usuarios de ejemplo. Para mostrar el mapa con contenido utiliza tu volumen local de PostgreSQL existente o carga datos propios. Las funciones basadas en modelos de lenguaje requieren credenciales válidas únicamente en el backend; nunca en este cliente Flutter.

## Estado y uso

Proyecto académico terminado, mantenido como muestra técnica de portafolio. El código se publica para evaluación y aprendizaje; no cuenta todavía con una licencia de código abierto.
