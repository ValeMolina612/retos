# Retos Flutter

Aplicación con tres experiencias pequeñas que consumen APIs:

- **Películas:** tendencias y recomendaciones por estado de ánimo con TMDB.
- **Memes de gatos:** imágenes de Cataas con texto y filtros personalizables.
- **Clima:** consulta del clima por ciudad con OpenWeatherMap.

## Ejecutar

Desde esta carpeta, instala las dependencias y ejecuta:

```powershell
flutter pub get
flutter run --dart-define="TMDB_API_KEY=tu_clave_tmdb" --dart-define="OPENWEATHERMAP_API_KEY=tu_clave_openweathermap"
```

Las claves son gratuitas y se obtienen en [TMDB](https://www.themoviedb.org/settings/api) y [OpenWeatherMap](https://openweathermap.org/api). OpenWeatherMap puede tardar un tiempo en activar una clave nueva. No guardes claves personales en el código fuente.

Los retos de gatos no necesitan clave. Si ejecutas la app sin una de las otras claves, ese reto mostrará un mensaje indicando cuál falta; los demás seguirán disponibles.
