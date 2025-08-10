# TODO List

## Completado ✅

- [x] Eliminar la tabla de unidades y migrar la estructura a un campo JSONB en cursos (hecho en Supabase).
- [x] Actualizar el modelo de curso para incluir unidades como lista JSON (hecho).
- [x] Actualizar el repositorio de cursos para leer y escribir unidades desde el campo JSON de cursos (hecho).
- [x] Actualizar la UI (widgets y providers) para consumir y mostrar las unidades desde el campo del curso, no desde una tabla aparte (hecho).
- [x] Eliminar el sistema de intentos de examen de la base de datos (hecho).
- [x] Crear el sistema de foros básico vinculado a cursos y unidades (hecho).
- [x] Corregir errores de linter en cursos.alumno.screen.dart (hecho).
- [x] Actualizar el estado del provider para incluir herramientaActiva (hecho).
- [x] Agregar el método cambiarHerramienta al notifier (hecho).

## En Progreso 🔄

- [ ] Probar el sistema de foros en la aplicación
- [ ] Verificar que las unidades se muestren correctamente desde el campo JSON del curso

## Pendiente 📋

- [ ] Crear formularios para editar/agregar unidades desde el curso
- [ ] Implementar funcionalidad completa del sistema de foros (crear, editar, comentar)
- [ ] Optimizar el rendimiento de la carga de unidades desde JSON
- [ ] Agregar validaciones para el sistema de foros
- [ ] Crear documentación del nuevo sistema de unidades integrado

## Notas

- Las unidades ahora están almacenadas como JSONB en la tabla `cursos`
- El sistema de foros está básicamente implementado pero necesita pruebas
- Se eliminó la tabla `intentos_examenes` para simplificar el sistema
- Los widgets de la UI han sido actualizados para usar los nuevos parámetros
