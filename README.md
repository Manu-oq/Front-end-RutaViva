# Front-end-RutaViva

Aplicación Flutter de Ruta Viva.

## Conexión con backend

La app usa Dio + Riverpod para consumir el backend FastAPI versionado en `/api/v1`.

Instala dependencias después de cambios de integración:

```bash
flutter pub get
```

Por defecto apunta a Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=API_ORIGIN=http://10.0.2.2:8000
```

Para web/escritorio local usa, por ejemplo:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=API_ORIGIN=http://127.0.0.1:8000
```

`API_ORIGIN` se usa para convertir URLs relativas devueltas por el backend, como `/media/...`, en URLs absolutas.

## Integraciones ya cableadas

- Auth JWT con persistencia local mediante `shared_preferences`.
- Guards de navegación con GoRouter + Riverpod.
- POIs cercanos, búsqueda semántica y detalle por UUID.
- Reviews por POI y creación de nuevas reviews.
- Upload local de imágenes hacia `/api/v1/media/upload`.
- Generación de itinerarios y renderizado con nombres reales de POIs cuando el backend los entrega.
- Categorías 100% data-driven desde backend (sin enums hardcodeados).
- Navegación inferior con NavigationBar Material 3 y ShellRoute.
- Persistencia del último itinerario en shared_preferences.
- Skeleton loaders, loading global overlay, error states con retry, pull-to-refresh.
- Tests: ~70 tests unitarios y widget tests.


## Estado actual de pantallas conectadas

- Login conectado a `/auth/login` y `/users/me`. Banner de error persistente.
- Registro separado conectado a `/auth/register`. Banner de error persistente.
- Home reemplaza el hero mock por POIs reales cargados desde backend. Navegación inferior con ShellRoute.
- Onboarding dispara búsquedas semánticas reales y abre el mapa.
- Profile muestra usuario y métricas reales de estado de app. Pull-to-refresh.
- Mapa con skeleton de 6 chips durante carga.
- POI detail con pull-to-refresh, skeleton en reviews, botón Reintentar.
- Itinerarios con skeleton, pull-to-refresh y persistencia local del último generado.
