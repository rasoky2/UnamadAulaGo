-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.calificaciones (
  id integer NOT NULL DEFAULT nextval('calificaciones_id_seq'::regclass),
  estudiante_id bigint,
  tarea_asignacion_id integer,
  puntos_obtenidos numeric,
  puntos_totales numeric,
  fecha_calificacion timestamp without time zone,
  calificado_por bigint,
  tarea_id integer,
  examen_id integer,
  curso_id integer,
  CONSTRAINT calificaciones_pkey PRIMARY KEY (id),
  CONSTRAINT calificaciones_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id),
  CONSTRAINT calificaciones_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id),
  CONSTRAINT calificaciones_tarea_id_fkey FOREIGN KEY (tarea_id) REFERENCES public.tareas(id)
);
CREATE TABLE public.carreras (
  id integer NOT NULL DEFAULT nextval('carreras_id_seq'::regclass),
  facultad_id integer,
  nombre text NOT NULL,
  codigo text NOT NULL UNIQUE,
  descripcion text,
  duracion_semestres integer NOT NULL DEFAULT 10,
  director_nombre text,
  director_email text,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT carreras_pkey PRIMARY KEY (id),
  CONSTRAINT carreras_facultad_id_fkey FOREIGN KEY (facultad_id) REFERENCES public.facultades(id)
);
CREATE TABLE public.comentarios_foro (
  id integer NOT NULL DEFAULT nextval('comentarios_foro_id_seq'::regclass),
  publicacion_id integer NOT NULL,
  contenido text NOT NULL,
  autor_id bigint NOT NULL,
  tipo_autor text DEFAULT 'estudiante'::text CHECK (tipo_autor = ANY (ARRAY['estudiante'::text, 'profesor'::text])),
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'publicado'::text CHECK (estado = ANY (ARRAY['publicado'::text, 'oculto'::text, 'eliminado'::text])),
  CONSTRAINT comentarios_foro_pkey PRIMARY KEY (id),
  CONSTRAINT comentarios_foro_publicacion_id_fkey FOREIGN KEY (publicacion_id) REFERENCES public.publicaciones_foro(id),
  CONSTRAINT comentarios_foro_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.cursos (
  id integer NOT NULL DEFAULT nextval('cursos_id_seq'::regclass),
  carrera_id integer NOT NULL,
  codigo_curso text NOT NULL,
  nombre text NOT NULL,
  descripcion text,
  creditos integer NOT NULL DEFAULT 3,
  horas_teoria integer DEFAULT 2,
  horas_practica integer DEFAULT 2,
  semestre_recomendado integer,
  es_obligatorio boolean DEFAULT true,
  fecha_creacion timestamp with time zone DEFAULT now(),
  profesor_id bigint,
  total_unidades integer DEFAULT 3,
  unidades jsonb DEFAULT '[]'::jsonb,
  CONSTRAINT cursos_pkey PRIMARY KEY (id),
  CONSTRAINT cursos_carrera_id_fkey FOREIGN KEY (carrera_id) REFERENCES public.carreras(id),
  CONSTRAINT cursos_profesor_id_fkey FOREIGN KEY (profesor_id) REFERENCES public.profesores(id)
);
CREATE TABLE public.entregas (
  id integer NOT NULL DEFAULT nextval('entregas_id_seq'::regclass),
  tarea_id integer NOT NULL,
  estudiante_id bigint NOT NULL,
  fecha_entrega timestamp with time zone NOT NULL DEFAULT now(),
  estado text NOT NULL CHECK (estado = ANY (ARRAY['Entregado'::text, 'Calificado'::text, 'Tarde'::text, 'No entregado'::text])),
  archivo_adjunto_url text,
  comentario_estudiante text,
  calificacion numeric,
  comentario_profesor text,
  fecha_calificacion timestamp with time zone,
  examen_id integer,
  archivos_adjuntos jsonb DEFAULT '[]'::jsonb,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  CONSTRAINT entregas_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_tarea_id_fkey FOREIGN KEY (tarea_id) REFERENCES public.tareas(id),
  CONSTRAINT entregas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT entregas_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id)
);
CREATE TABLE public.entregas_asignaciones (
  id integer NOT NULL DEFAULT nextval('entregas_asignaciones_id_seq'::regclass),
  tarea_asignacion_id integer,
  estudiante_id bigint,
  texto_entrega text,
  archivos_adjuntos jsonb,
  fecha_entrega timestamp with time zone DEFAULT now(),
  puntos_obtenidos numeric,
  retroalimentacion text,
  estado text DEFAULT 'submitted'::text CHECK (estado = ANY (ARRAY['submitted'::text, 'graded'::text, 'late'::text, 'missing'::text])),
  CONSTRAINT entregas_asignaciones_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_asignaciones_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT entregas_asignaciones_tarea_asignacion_id_fkey FOREIGN KEY (tarea_asignacion_id) REFERENCES public.tareas_asignaciones(id)
);
CREATE TABLE public.entregas_tareas (
  id integer NOT NULL DEFAULT nextval('entregas_tareas_id_seq'::regclass),
  tarea_id integer NOT NULL,
  estudiante_id bigint NOT NULL,
  contenido text,
  archivos_adjuntos jsonb,
  fecha_entrega timestamp with time zone DEFAULT now(),
  calificacion numeric,
  comentarios_profesor text,
  entrega_tardia boolean DEFAULT false,
  CONSTRAINT entregas_tareas_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_tareas_tarea_id_fkey FOREIGN KEY (tarea_id) REFERENCES public.tareas(id),
  CONSTRAINT entregas_tareas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.estudiantes (
  id bigint NOT NULL DEFAULT nextval('estudiantes_id_seq'::regclass),
  codigo_estudiante text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text,
  telefono text,
  fecha_nacimiento date,
  direccion text,
  carrera_id integer,
  semestre_actual integer DEFAULT 1,
  estado text DEFAULT 'activo'::text,
  rol text DEFAULT 'estudiante'::text,
  fecha_ingreso date DEFAULT CURRENT_DATE,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  usuario_id bigint,
  foto_perfil_url text,
  CONSTRAINT estudiantes_pkey PRIMARY KEY (id),
  CONSTRAINT fk_estudiantes_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT estudiantes_carrera_id_fkey FOREIGN KEY (carrera_id) REFERENCES public.carreras(id)
);
CREATE TABLE public.examenes (
  id integer NOT NULL DEFAULT nextval('examenes_id_seq'::regclass),
  titulo text NOT NULL,
  descripcion text,
  instrucciones text,
  fecha_disponible timestamp with time zone NOT NULL,
  fecha_limite timestamp with time zone NOT NULL,
  duracion_minutos integer DEFAULT 120,
  intentos_permitidos integer DEFAULT 1,
  puntos_maximos numeric DEFAULT 20.00,
  tipo_examen text DEFAULT 'parcial'::text CHECK (tipo_examen = ANY (ARRAY['parcial'::text, 'final'::text, 'practica'::text, 'quiz'::text])),
  aleatorizar_preguntas boolean DEFAULT false,
  estado text DEFAULT 'borrador'::text CHECK (estado = ANY (ARRAY['borrador'::text, 'publicado'::text, 'finalizado'::text])),
  fecha_creacion timestamp with time zone DEFAULT now(),
  curso_id integer,
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  fecha_publicacion_resultados timestamp with time zone,
  CONSTRAINT examenes_pkey PRIMARY KEY (id),
  CONSTRAINT examenes_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.examenes_entregas (
  id integer NOT NULL DEFAULT nextval('examenes_entregas_id_seq'::regclass),
  examen_id integer,
  estudiante_id bigint,
  fecha_inicio timestamp with time zone DEFAULT now(),
  fecha_fin timestamp with time zone,
  calificacion numeric,
  intento integer NOT NULL,
  estado text NOT NULL,
  respuestas jsonb DEFAULT '[]'::jsonb,
  CONSTRAINT examenes_entregas_pkey PRIMARY KEY (id),
  CONSTRAINT examenes_entregas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT examenes_entregas_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id)
);
CREATE TABLE public.facultades (
  id integer NOT NULL DEFAULT nextval('facultades_id_seq'::regclass),
  nombre text NOT NULL,
  codigo text NOT NULL UNIQUE,
  descripcion text,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT facultades_pkey PRIMARY KEY (id)
);
CREATE TABLE public.fechas_importantes (
  id integer NOT NULL DEFAULT nextval('fechas_importantes_id_seq'::regclass),
  titulo text NOT NULL,
  descripcion text,
  fecha_evento date NOT NULL,
  categoria text,
  CONSTRAINT fechas_importantes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.foros (
  id integer NOT NULL DEFAULT nextval('foros_id_seq'::regclass),
  titulo text NOT NULL,
  descripcion text,
  curso_id integer NOT NULL,
  unidad_id integer,
  creado_por bigint,
  fecha_creacion timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'activo'::text CHECK (estado = ANY (ARRAY['activo'::text, 'inactivo'::text, 'archivado'::text])),
  CONSTRAINT foros_pkey PRIMARY KEY (id),
  CONSTRAINT foros_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.profesores(id),
  CONSTRAINT foros_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.lecturas (
  id integer NOT NULL DEFAULT nextval('lecturas_id_seq'::regclass),
  titulo text NOT NULL,
  descripcion text,
  enlace_pdf text NOT NULL,
  CONSTRAINT lecturas_pkey PRIMARY KEY (id)
);
CREATE TABLE public.matriculas (
  id integer NOT NULL DEFAULT nextval('matriculas_id_seq'::regclass),
  estudiante_id bigint NOT NULL,
  periodo_academico_id integer NOT NULL,
  fecha_matricula timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'matriculado'::text,
  nota_final numeric,
  fecha_retiro date,
  curso_id integer,
  CONSTRAINT matriculas_pkey PRIMARY KEY (id),
  CONSTRAINT matriculas_periodo_academico_id_fkey FOREIGN KEY (periodo_academico_id) REFERENCES public.periodos_academicos(id),
  CONSTRAINT matriculas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT matriculas_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.periodos_academicos (
  id integer NOT NULL DEFAULT nextval('periodos_academicos_id_seq'::regclass),
  nombre text NOT NULL,
  anio integer NOT NULL,
  semestre integer NOT NULL CHECK (semestre = ANY (ARRAY[1, 2])),
  fecha_inicio date NOT NULL,
  fecha_fin date NOT NULL,
  fecha_matricula_inicio date,
  fecha_matricula_fin date,
  estado text DEFAULT 'planificado'::text,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT periodos_academicos_pkey PRIMARY KEY (id)
);
CREATE TABLE public.preguntas_examen (
  id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
  examen_id integer NOT NULL,
  enunciado text NOT NULL,
  tipo text NOT NULL DEFAULT 'opcion_multiple'::text CHECK (tipo = ANY (ARRAY['opcion_multiple'::text, 'abierta'::text])),
  opciones jsonb NOT NULL DEFAULT '[]'::jsonb,
  respuesta_correcta text,
  puntos numeric DEFAULT 1,
  CONSTRAINT preguntas_examen_pkey PRIMARY KEY (id),
  CONSTRAINT preguntas_examen_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id)
);
CREATE TABLE public.profesores (
  id bigint NOT NULL DEFAULT nextval('profesores_id_seq'::regclass),
  codigo_profesor text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text,
  telefono text,
  especialidad text,
  grado_academico text,
  facultad_id integer,
  estado text DEFAULT 'activo'::text,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  usuario_id bigint,
  foto_perfil_url text,
  CONSTRAINT profesores_pkey PRIMARY KEY (id),
  CONSTRAINT fk_profesores_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT profesores_facultad_id_fkey FOREIGN KEY (facultad_id) REFERENCES public.facultades(id)
);
CREATE TABLE public.publicaciones_foro (
  id integer NOT NULL DEFAULT nextval('publicaciones_foro_id_seq'::regclass),
  foro_id integer NOT NULL,
  titulo text NOT NULL,
  contenido text NOT NULL,
  autor_id bigint NOT NULL,
  tipo_autor text DEFAULT 'estudiante'::text CHECK (tipo_autor = ANY (ARRAY['estudiante'::text, 'profesor'::text])),
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'publicado'::text CHECK (estado = ANY (ARRAY['publicado'::text, 'oculto'::text, 'eliminado'::text])),
  CONSTRAINT publicaciones_foro_pkey PRIMARY KEY (id),
  CONSTRAINT publicaciones_foro_foro_id_fkey FOREIGN KEY (foro_id) REFERENCES public.foros(id),
  CONSTRAINT publicaciones_foro_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.tareas (
  id integer NOT NULL DEFAULT nextval('tareas_id_seq'::regclass),
  titulo text NOT NULL,
  descripcion text,
  instrucciones text,
  fecha_asignacion timestamp with time zone DEFAULT now(),
  fecha_entrega timestamp with time zone NOT NULL,
  puntos_maximos numeric DEFAULT 20.00,
  estado text DEFAULT 'activa'::text,
  curso_id integer,
  CONSTRAINT tareas_pkey PRIMARY KEY (id),
  CONSTRAINT tareas_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.tareas_asignaciones (
  id integer NOT NULL DEFAULT nextval('tareas_asignaciones_id_seq'::regclass),
  titulo text NOT NULL,
  descripcion text,
  tipo_asignacion text CHECK (tipo_asignacion = ANY (ARRAY['homework'::text, 'project'::text, 'exam'::text, 'quiz'::text, 'presentation'::text])),
  fecha_vencimiento timestamp with time zone,
  puntos_totales numeric DEFAULT 100,
  instrucciones text,
  archivos_adjuntos jsonb,
  esta_publicado boolean DEFAULT false,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT tareas_asignaciones_pkey PRIMARY KEY (id)
);
CREATE TABLE public.temas_unidad (
  id integer NOT NULL DEFAULT nextval('temas_unidad_id_seq'::regclass),
  unidad_id integer,
  titulo text NOT NULL,
  tipo text NOT NULL,
  icono text,
  orden integer,
  CONSTRAINT temas_unidad_pkey PRIMARY KEY (id),
  CONSTRAINT temas_unidad_unidad_id_fkey FOREIGN KEY (unidad_id) REFERENCES public.unidades_curso(id)
);
CREATE TABLE public.unidades_curso (
  id integer NOT NULL DEFAULT nextval('unidades_curso_id_seq'::regclass),
  curso_id integer NOT NULL,
  numero_unidad integer NOT NULL,
  titulo text NOT NULL,
  descripcion text,
  objetivos ARRAY,
  semanas_duracion integer DEFAULT 4,
  orden_secuencial integer,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT unidades_curso_pkey PRIMARY KEY (id),
  CONSTRAINT unidades_curso_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.usuarios (
  id bigint NOT NULL DEFAULT nextval('usuarios_id_seq'::regclass),
  codigo_usuario text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text UNIQUE,
  rol text NOT NULL CHECK (rol = ANY (ARRAY['admin'::text, 'profesor'::text, 'estudiante'::text])),
  activo boolean DEFAULT true,
  fecha_creacion timestamp with time zone DEFAULT now(),
  foto_perfil_url text,
  CONSTRAINT usuarios_pkey PRIMARY KEY (id)
);