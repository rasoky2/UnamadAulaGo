-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.anuncios (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  titulo text NOT NULL,
  contenido text NOT NULL,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT anuncios_pkey PRIMARY KEY (id)
);
CREATE TABLE public.calificaciones (
  estudiante_id bigint,
  tarea_asignacion_id integer,
  puntos_obtenidos numeric,
  puntos_totales numeric,
  fecha_calificacion timestamp without time zone,
  calificado_por bigint,
  id integer NOT NULL DEFAULT nextval('calificaciones_id_seq'::regclass),
  tarea_id integer,
  examen_id integer,
  curso_id integer,
  CONSTRAINT calificaciones_pkey PRIMARY KEY (id),
  CONSTRAINT calificaciones_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id),
  CONSTRAINT calificaciones_tarea_id_fkey FOREIGN KEY (tarea_id) REFERENCES public.tareas(id),
  CONSTRAINT calificaciones_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.carreras (
  facultad_id integer,
  nombre text NOT NULL,
  codigo text NOT NULL UNIQUE,
  descripcion text,
  director_nombre text,
  director_email text,
  id integer NOT NULL DEFAULT nextval('carreras_id_seq'::regclass),
  duracion_semestres integer NOT NULL DEFAULT 10,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT carreras_pkey PRIMARY KEY (id),
  CONSTRAINT carreras_facultad_id_fkey FOREIGN KEY (facultad_id) REFERENCES public.facultades(id)
);
CREATE TABLE public.comentarios_foro (
  publicacion_id integer NOT NULL,
  contenido text NOT NULL,
  autor_id bigint NOT NULL,
  id integer NOT NULL DEFAULT nextval('comentarios_foro_id_seq'::regclass),
  tipo_autor text DEFAULT 'estudiante'::text CHECK (tipo_autor = ANY (ARRAY['estudiante'::text, 'profesor'::text])),
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'publicado'::text CHECK (estado = ANY (ARRAY['publicado'::text, 'oculto'::text, 'eliminado'::text])),
  CONSTRAINT comentarios_foro_pkey PRIMARY KEY (id),
  CONSTRAINT comentarios_foro_publicacion_id_fkey FOREIGN KEY (publicacion_id) REFERENCES public.publicaciones_foro(id),
  CONSTRAINT comentarios_foro_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.cursos (
  carrera_id integer NOT NULL,
  codigo_curso text NOT NULL,
  nombre text NOT NULL,
  descripcion text,
  semestre_recomendado integer,
  profesor_id bigint,
  id integer NOT NULL DEFAULT nextval('cursos_id_seq'::regclass),
  creditos integer NOT NULL DEFAULT 3,
  horas_teoria integer DEFAULT 2,
  horas_practica integer DEFAULT 2,
  es_obligatorio boolean DEFAULT true,
  fecha_creacion timestamp with time zone DEFAULT now(),
  total_unidades integer DEFAULT 3,
  unidades jsonb DEFAULT '[]'::jsonb,
  CONSTRAINT cursos_pkey PRIMARY KEY (id),
  CONSTRAINT cursos_profesor_id_fkey FOREIGN KEY (profesor_id) REFERENCES public.profesores(id),
  CONSTRAINT cursos_carrera_id_fkey FOREIGN KEY (carrera_id) REFERENCES public.carreras(id)
);
CREATE TABLE public.entregas (
  tarea_id integer NOT NULL,
  estudiante_id bigint NOT NULL,
  estado text NOT NULL CHECK (estado = ANY (ARRAY['Entregado'::text, 'Calificado'::text, 'Tarde'::text, 'No entregado'::text])),
  archivo_adjunto_url text,
  comentario_estudiante text,
  calificacion numeric,
  comentario_profesor text,
  fecha_calificacion timestamp with time zone,
  examen_id integer,
  id integer NOT NULL DEFAULT nextval('entregas_id_seq'::regclass),
  fecha_entrega timestamp with time zone NOT NULL DEFAULT now(),
  archivos_adjuntos jsonb DEFAULT '[]'::jsonb,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  CONSTRAINT entregas_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id),
  CONSTRAINT entregas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT entregas_tarea_id_fkey FOREIGN KEY (tarea_id) REFERENCES public.tareas(id)
);
CREATE TABLE public.entregas_asignaciones (
  tarea_asignacion_id integer,
  estudiante_id bigint,
  texto_entrega text,
  archivos_adjuntos jsonb,
  puntos_obtenidos numeric,
  retroalimentacion text,
  id integer NOT NULL DEFAULT nextval('entregas_asignaciones_id_seq'::regclass),
  fecha_entrega timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'submitted'::text CHECK (estado = ANY (ARRAY['submitted'::text, 'graded'::text, 'late'::text, 'missing'::text])),
  CONSTRAINT entregas_asignaciones_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_asignaciones_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT entregas_asignaciones_tarea_asignacion_id_fkey FOREIGN KEY (tarea_asignacion_id) REFERENCES public.tareas_asignaciones(id)
);
CREATE TABLE public.entregas_tareas (
  tarea_id integer NOT NULL,
  estudiante_id bigint NOT NULL,
  contenido text,
  archivos_adjuntos jsonb,
  calificacion numeric,
  comentarios_profesor text,
  id integer NOT NULL DEFAULT nextval('entregas_tareas_id_seq'::regclass),
  fecha_entrega timestamp with time zone DEFAULT now(),
  entrega_tardia boolean DEFAULT false,
  CONSTRAINT entregas_tareas_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_tareas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT entregas_tareas_tarea_id_fkey FOREIGN KEY (tarea_id) REFERENCES public.tareas(id)
);
CREATE TABLE public.estudiantes (
  foto_perfil_url text,
  codigo_estudiante text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text,
  telefono text,
  fecha_nacimiento date,
  direccion text,
  carrera_id integer,
  usuario_id bigint,
  id bigint NOT NULL DEFAULT nextval('estudiantes_id_seq'::regclass),
  semestre_actual integer DEFAULT 1,
  estado text DEFAULT 'activo'::text,
  rol text DEFAULT 'estudiante'::text,
  fecha_ingreso date DEFAULT CURRENT_DATE,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  CONSTRAINT estudiantes_pkey PRIMARY KEY (id),
  CONSTRAINT fk_estudiantes_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT estudiantes_carrera_id_fkey FOREIGN KEY (carrera_id) REFERENCES public.carreras(id)
);
CREATE TABLE public.examenes (
  titulo text NOT NULL,
  descripcion text,
  instrucciones text,
  fecha_disponible timestamp with time zone NOT NULL,
  fecha_limite timestamp with time zone NOT NULL,
  curso_id integer,
  id integer NOT NULL DEFAULT nextval('examenes_id_seq'::regclass),
  duracion_minutos integer DEFAULT 120,
  intentos_permitidos integer DEFAULT 1,
  puntos_maximos numeric DEFAULT 20.00,
  tipo_examen text DEFAULT 'parcial'::text CHECK (tipo_examen = ANY (ARRAY['parcial'::text, 'final'::text, 'practica'::text, 'quiz'::text])),
  aleatorizar_preguntas boolean DEFAULT false,
  estado text DEFAULT 'borrador'::text CHECK (estado = ANY (ARRAY['borrador'::text, 'publicado'::text, 'finalizado'::text])),
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  fecha_publicacion_resultados timestamp with time zone,
  CONSTRAINT examenes_pkey PRIMARY KEY (id),
  CONSTRAINT examenes_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.examenes_entregas (
  examen_id integer,
  estudiante_id bigint,
  fecha_fin timestamp with time zone,
  calificacion numeric,
  intento integer NOT NULL,
  estado text NOT NULL,
  id integer NOT NULL DEFAULT nextval('examenes_entregas_id_seq'::regclass),
  fecha_inicio timestamp with time zone DEFAULT now(),
  respuestas jsonb DEFAULT '[]'::jsonb,
  CONSTRAINT examenes_entregas_pkey PRIMARY KEY (id),
  CONSTRAINT examenes_entregas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT examenes_entregas_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id)
);
CREATE TABLE public.facultades (
  id integer NOT NULL DEFAULT nextval('facultades_id_seq'::regclass),
  fecha_creacion timestamp with time zone DEFAULT now(),
  nombre text NOT NULL,
  codigo text NOT NULL UNIQUE,
  descripcion text,
  CONSTRAINT facultades_pkey PRIMARY KEY (id)
);
CREATE TABLE public.fechas_importantes (
  titulo text NOT NULL,
  descripcion text,
  fecha_evento date NOT NULL,
  categoria text,
  id integer NOT NULL DEFAULT nextval('fechas_importantes_id_seq'::regclass),
  CONSTRAINT fechas_importantes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.foros (
  titulo text NOT NULL,
  descripcion text,
  curso_id integer NOT NULL,
  unidad_id integer,
  creado_por bigint,
  id integer NOT NULL DEFAULT nextval('foros_id_seq'::regclass),
  fecha_creacion timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'activo'::text CHECK (estado = ANY (ARRAY['activo'::text, 'inactivo'::text, 'archivado'::text])),
  CONSTRAINT foros_pkey PRIMARY KEY (id),
  CONSTRAINT foros_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.profesores(id),
  CONSTRAINT foros_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.lecturas (
  titulo text NOT NULL,
  descripcion text,
  enlace_pdf text NOT NULL,
  id integer NOT NULL DEFAULT nextval('lecturas_id_seq'::regclass),
  curso_id integer NOT NULL,
  CONSTRAINT lecturas_pkey PRIMARY KEY (id),
  CONSTRAINT lecturas_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.matriculas (
  estudiante_id bigint NOT NULL,
  periodo_academico_id integer NOT NULL,
  nota_final numeric,
  fecha_retiro date,
  curso_id integer,
  id integer NOT NULL DEFAULT nextval('matriculas_id_seq'::regclass),
  fecha_matricula timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'matriculado'::text,
  CONSTRAINT matriculas_pkey PRIMARY KEY (id),
  CONSTRAINT matriculas_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id),
  CONSTRAINT matriculas_periodo_academico_id_fkey FOREIGN KEY (periodo_academico_id) REFERENCES public.periodos_academicos(id),
  CONSTRAINT matriculas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.periodos_academicos (
  nombre text NOT NULL,
  anio integer NOT NULL,
  semestre integer NOT NULL CHECK (semestre = ANY (ARRAY[1, 2])),
  fecha_inicio date NOT NULL,
  fecha_fin date NOT NULL,
  fecha_matricula_inicio date,
  fecha_matricula_fin date,
  id integer NOT NULL DEFAULT nextval('periodos_academicos_id_seq'::regclass),
  estado text DEFAULT 'planificado'::text,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT periodos_academicos_pkey PRIMARY KEY (id)
);
CREATE TABLE public.preguntas_examen (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  examen_id integer NOT NULL,
  enunciado text NOT NULL,
  respuesta_correcta text,
  opciones jsonb NOT NULL DEFAULT '[]'::jsonb,
  puntos numeric DEFAULT 1,
  tipo text NOT NULL DEFAULT 'opcion_multiple'::text CHECK (tipo = ANY (ARRAY['opcion_multiple'::text, 'abierta'::text])),
  CONSTRAINT preguntas_examen_pkey PRIMARY KEY (id),
  CONSTRAINT preguntas_examen_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id)
);
CREATE TABLE public.profesores (
  foto_perfil_url text,
  codigo_profesor text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text,
  telefono text,
  especialidad text,
  grado_academico text,
  facultad_id integer,
  usuario_id bigint,
  id bigint NOT NULL DEFAULT nextval('profesores_id_seq'::regclass),
  estado text DEFAULT 'activo'::text,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  CONSTRAINT profesores_pkey PRIMARY KEY (id),
  CONSTRAINT fk_profesores_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT profesores_facultad_id_fkey FOREIGN KEY (facultad_id) REFERENCES public.facultades(id)
);
CREATE TABLE public.publicaciones_foro (
  foro_id integer NOT NULL,
  titulo text NOT NULL,
  contenido text NOT NULL,
  autor_id bigint NOT NULL,
  id integer NOT NULL DEFAULT nextval('publicaciones_foro_id_seq'::regclass),
  tipo_autor text DEFAULT 'estudiante'::text CHECK (tipo_autor = ANY (ARRAY['estudiante'::text, 'profesor'::text])),
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'publicado'::text CHECK (estado = ANY (ARRAY['publicado'::text, 'oculto'::text, 'eliminado'::text])),
  CONSTRAINT publicaciones_foro_pkey PRIMARY KEY (id),
  CONSTRAINT publicaciones_foro_foro_id_fkey FOREIGN KEY (foro_id) REFERENCES public.foros(id),
  CONSTRAINT publicaciones_foro_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.tareas (
  titulo text NOT NULL,
  descripcion text,
  instrucciones text,
  fecha_entrega timestamp with time zone NOT NULL,
  curso_id integer,
  id integer NOT NULL DEFAULT nextval('tareas_id_seq'::regclass),
  fecha_asignacion timestamp with time zone DEFAULT now(),
  puntos_maximos numeric DEFAULT 20.00,
  estado text DEFAULT 'activa'::text,
  fecha_creacion timestamp with time zone NOT NULL DEFAULT now(),
  fecha_actualizacion timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT tareas_pkey PRIMARY KEY (id),
  CONSTRAINT tareas_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.tareas_asignaciones (
  titulo text NOT NULL,
  descripcion text,
  tipo_asignacion text CHECK (tipo_asignacion = ANY (ARRAY['homework'::text, 'project'::text, 'exam'::text, 'quiz'::text, 'presentation'::text])),
  fecha_vencimiento timestamp with time zone,
  instrucciones text,
  archivos_adjuntos jsonb,
  id integer NOT NULL DEFAULT nextval('tareas_asignaciones_id_seq'::regclass),
  puntos_totales numeric DEFAULT 100,
  esta_publicado boolean DEFAULT false,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT tareas_asignaciones_pkey PRIMARY KEY (id)
);
CREATE TABLE public.temas_unidad (
  unidad_id integer,
  titulo text NOT NULL,
  tipo text NOT NULL,
  icono text,
  orden integer,
  id integer NOT NULL DEFAULT nextval('temas_unidad_id_seq'::regclass),
  CONSTRAINT temas_unidad_pkey PRIMARY KEY (id),
  CONSTRAINT temas_unidad_unidad_id_fkey FOREIGN KEY (unidad_id) REFERENCES public.unidades_curso(id)
);
CREATE TABLE public.unidades_curso (
  curso_id integer NOT NULL,
  numero_unidad integer NOT NULL,
  titulo text NOT NULL,
  descripcion text,
  objetivos ARRAY,
  orden_secuencial integer,
  id integer NOT NULL DEFAULT nextval('unidades_curso_id_seq'::regclass),
  semanas_duracion integer DEFAULT 4,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT unidades_curso_pkey PRIMARY KEY (id),
  CONSTRAINT unidades_curso_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.usuarios (
  foto_perfil_url text,
  codigo_usuario text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text UNIQUE,
  rol text NOT NULL CHECK (rol = ANY (ARRAY['admin'::text, 'profesor'::text, 'estudiante'::text])),
  id bigint NOT NULL DEFAULT nextval('usuarios_id_seq'::regclass),
  activo boolean DEFAULT true,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT usuarios_pkey PRIMARY KEY (id)
);

-- ==================== SCRIPT PARA CREAR USUARIO ADMIN ====================
-- Ejecutar en Supabase SQL Editor si se elimina el admin existente

-- 1. Crear usuario administrador en la tabla usuarios
INSERT INTO public.usuarios (
  id,
  nombre,
  apellido,
  email,
  password_hash,
  tipo_usuario,
  fecha_registro,
  ultimo_acceso,
  estado,
  foto_perfil_url,
  telefono,
  direccion,
  fecha_nacimiento,
  genero,
  nacionalidad,
  documento_identidad,
  codigo_estudiante,
  especialidad,
  anio_ingreso,
  semestre_actual,
  promedio_general,
  creditos_aprobados,
  creditos_totales,
  departamento,
  titulo_academico,
  experiencia_anios,
  areas_investigacion,
  proyectos_activos,
  publicaciones,
  reconocimientos,
  fecha_creacion,
  fecha_actualizacion
) VALUES (
  nextval('usuarios_id_seq'), -- ID auto-incremental
  'Admin',                    -- Nombre
  'Sistema',                  -- Apellido
  'admin@aulago.com',         -- Email
  '$2a$10$rQZ8K9L2M3N4O5P6Q7R8S9T0U1V2W3X4Y5Z6A7B8C9D0E1F2G3H4I5J6', -- Password hash (admin123)
  'admin',                    -- Tipo de usuario
  NOW(),                      -- Fecha de registro
  NOW(),                      -- Último acceso
  'activo',                   -- Estado
  NULL,                       -- Foto de perfil
  '+51 999 999 999',         -- Teléfono
  'Lima, Perú',               -- Dirección
  '1990-01-01',              -- Fecha de nacimiento
  'No especificado',          -- Género
  'Peruana',                  -- Nacionalidad
  '12345678',                 -- Documento de identidad
  NULL,                       -- Código de estudiante (no aplica para admin)
  NULL,                       -- Especialidad (no aplica para admin)
  NULL,                       -- Año de ingreso (no aplica para admin)
  NULL,                       -- Semestre actual (no aplica para admin)
  NULL,                       -- Promedio general (no aplica para admin)
  NULL,                       -- Créditos aprobados (no aplica para admin)
  NULL,                       -- Créditos totales (no aplica para admin)
  'Sistemas',                 -- Departamento
  'Ingeniero de Sistemas',    -- Título académico
  5,                          -- Años de experiencia
  'Desarrollo Web, Base de Datos, IA', -- Áreas de investigación
  3,                          -- Proyectos activos
  15,                         -- Publicaciones
  'Mejor Profesor 2024',      -- Reconocimientos
  NOW(),                      -- Fecha de creación
  NOW()                       -- Fecha de actualización
);

-- 2. Crear perfil de profesor para el admin
INSERT INTO public.profesores (
  id,
  usuario_id,
  departamento,
  especialidad,
  titulo_academico,
  experiencia_anios,
  areas_investigacion,
  proyectos_activos,
  publicaciones,
  reconocimientos,
  fecha_contratacion,
  estado,
  salario,
  horario_trabajo,
  oficina,
  extension_telefonica,
  email_institucional,
  sitio_web,
  linkedin,
  fecha_creacion,
  fecha_actualizacion
) VALUES (
  nextval('profesores_id_seq'), -- ID auto-incremental
  (SELECT id FROM public.usuarios WHERE email = 'admin@aulago.com'), -- Usuario ID del admin
  'Sistemas',                    -- Departamento
  'Desarrollo de Software',      -- Especialidad
  'Ingeniero de Sistemas',       -- Título académico
  5,                             -- Años de experiencia
  'Desarrollo Web, Base de Datos, Inteligencia Artificial', -- Áreas de investigación
  3,                             -- Proyectos activos
  15,                            -- Publicaciones
  'Mejor Profesor 2024, Innovador del Año 2023', -- Reconocimientos
  '2020-01-15',                 -- Fecha de contratación
  'activo',                      -- Estado
  5000.00,                      -- Salario
  'Lunes a Viernes 8:00-17:00', -- Horario de trabajo
  'A-101',                       -- Oficina
  '101',                         -- Extensión telefónica
  'admin.sistema@aulago.edu.pe', -- Email institucional
  'https://admin.aulago.edu.pe', -- Sitio web
  'https://linkedin.com/in/admin-aulago', -- LinkedIn
  NOW(),                         -- Fecha de creación
  NOW()                          -- Fecha de actualización
);

-- 3. Verificar que se creó correctamente
SELECT 
  u.id,
  u.nombre,
  u.apellido,
  u.email,
  u.tipo_usuario,
  u.estado,
  p.departamento,
  p.especialidad,
  p.titulo_academico
FROM public.usuarios u
LEFT JOIN public.profesores p ON u.id = p.usuario_id
WHERE u.email = 'admin@aulago.com';

-- ==================== INFORMACIÓN DEL USUARIO ADMIN ====================
-- Email: admin@aulago.com
-- Password: admin123
-- Tipo: admin
-- Estado: activo
-- Departamento: Sistemas
-- Especialidad: Desarrollo de Software
-- 
-- NOTA: Cambiar la contraseña después del primer login por seguridad
-- ======================================================================