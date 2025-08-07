-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.anuncios_generales (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  contenido text NOT NULL,
  fecha_publicacion timestamp with time zone DEFAULT now(),
  creado_por text,
  tipo_anuncio text,
  CONSTRAINT anuncios_generales_pkey PRIMARY KEY (id)
);
CREATE TABLE public.asistencia_videoconferencias (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  videoconferencia_id uuid NOT NULL,
  estudiante_id uuid NOT NULL,
  estado_asistencia text DEFAULT 'pendiente'::text CHECK (estado_asistencia = ANY (ARRAY['presente'::text, 'ausente'::text, 'tardanza'::text, 'pendiente'::text])),
  hora_entrada timestamp with time zone,
  hora_salida timestamp with time zone,
  minutos_conectado integer DEFAULT 0,
  fecha_registro timestamp with time zone DEFAULT now(),
  CONSTRAINT asistencia_videoconferencias_pkey PRIMARY KEY (id),
  CONSTRAINT asistencia_videoconferencias_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT asistencia_videoconferencias_videoconferencia_id_fkey FOREIGN KEY (videoconferencia_id) REFERENCES public.videoconferencias(id)
);
CREATE TABLE public.calificaciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  estudiante_id uuid,
  grupo_clase_id uuid,
  tarea_asignacion_id uuid,
  puntos_obtenidos numeric NOT NULL,
  puntos_totales numeric NOT NULL,
  porcentaje numeric DEFAULT ((puntos_obtenidos / puntos_totales) * (100)::numeric),
  calificacion_letra text,
  comentarios text,
  fecha_calificacion timestamp with time zone DEFAULT now(),
  calificado_por uuid,
  CONSTRAINT calificaciones_pkey PRIMARY KEY (id),
  CONSTRAINT calificaciones_tarea_asignacion_id_fkey FOREIGN KEY (tarea_asignacion_id) REFERENCES public.tareas_asignaciones(id)
);
CREATE TABLE public.carreras (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  facultad_id uuid NOT NULL,
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
CREATE TABLE public.conversaciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre text,
  tipo_conversacion text DEFAULT 'privada'::text CHECK (tipo_conversacion = ANY (ARRAY['privada'::text, 'grupo'::text, 'profesor_estudiante'::text])),
  grupo_clase_id uuid,
  descripcion text,
  imagen_avatar text,
  es_activa boolean DEFAULT true,
  creado_por uuid,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT conversaciones_pkey PRIMARY KEY (id)
);
CREATE TABLE public.cursos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  carrera_id uuid NOT NULL,
  codigo_curso text NOT NULL,
  nombre text NOT NULL,
  descripcion text,
  creditos integer NOT NULL DEFAULT 3,
  horas_teoria integer DEFAULT 2,
  horas_practica integer DEFAULT 2,
  semestre_recomendado integer,
  es_obligatorio boolean DEFAULT true,
  fecha_creacion timestamp with time zone DEFAULT now(),
  profesor_id uuid,
  total_unidades integer DEFAULT 3,
  CONSTRAINT cursos_pkey PRIMARY KEY (id),
  CONSTRAINT cursos_profesor_id_fkey FOREIGN KEY (profesor_id) REFERENCES public.profesores(id),
  CONSTRAINT cursos_carrera_id_fkey FOREIGN KEY (carrera_id) REFERENCES public.carreras(id)
);
CREATE TABLE public.entregas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tarea_id uuid NOT NULL,
  estudiante_id uuid NOT NULL,
  fecha_entrega timestamp with time zone NOT NULL DEFAULT now(),
  estado text NOT NULL CHECK (estado = ANY (ARRAY['Entregado'::text, 'Calificado'::text, 'Tarde'::text, 'No entregado'::text])),
  archivo_adjunto_url text,
  comentario_estudiante text,
  calificacion numeric,
  comentario_profesor text,
  fecha_calificacion timestamp with time zone,
  examen_id uuid,
  CONSTRAINT entregas_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT entregas_tarea_id_fkey FOREIGN KEY (tarea_id) REFERENCES public.tareas(id)
);
CREATE TABLE public.entregas_asignaciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tarea_asignacion_id uuid,
  estudiante_id uuid,
  texto_entrega text,
  archivos_adjuntos jsonb,
  fecha_entrega timestamp with time zone DEFAULT now(),
  puntos_obtenidos numeric,
  retroalimentacion text,
  estado text DEFAULT 'submitted'::text CHECK (estado = ANY (ARRAY['submitted'::text, 'graded'::text, 'late'::text, 'missing'::text])),
  CONSTRAINT entregas_asignaciones_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_asignaciones_tarea_asignacion_id_fkey FOREIGN KEY (tarea_asignacion_id) REFERENCES public.tareas_asignaciones(id)
);
CREATE TABLE public.entregas_tareas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tarea_id uuid NOT NULL,
  estudiante_id uuid NOT NULL,
  contenido text,
  archivos_adjuntos jsonb,
  fecha_entrega timestamp with time zone DEFAULT now(),
  calificacion numeric,
  comentarios_profesor text,
  entrega_tardia boolean DEFAULT false,
  CONSTRAINT entregas_tareas_pkey PRIMARY KEY (id),
  CONSTRAINT entregas_tareas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT entregas_tareas_tarea_id_fkey FOREIGN KEY (tarea_id) REFERENCES public.tareas(id)
);
CREATE TABLE public.estudiantes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  codigo_estudiante text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text,
  telefono text,
  fecha_nacimiento date,
  direccion text,
  carrera_id uuid,
  semestre_actual integer DEFAULT 1,
  estado text DEFAULT 'activo'::text,
  rol text DEFAULT 'estudiante'::text,
  fecha_ingreso date DEFAULT CURRENT_DATE,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  usuario_id uuid,
  CONSTRAINT estudiantes_pkey PRIMARY KEY (id),
  CONSTRAINT estudiantes_carrera_id_fkey FOREIGN KEY (carrera_id) REFERENCES public.carreras(id),
  CONSTRAINT fk_estudiantes_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.eventos_calendario (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descripcion text,
  tipo_evento text DEFAULT 'clase'::text CHECK (tipo_evento = ANY (ARRAY['clase'::text, 'examen'::text, 'tarea'::text, 'videoconferencia'::text, 'foro'::text, 'proyecto'::text, 'festivo'::text])),
  fecha_inicio timestamp with time zone NOT NULL,
  fecha_fin timestamp with time zone,
  todo_el_dia boolean DEFAULT false,
  ubicacion text,
  color_evento character varying DEFAULT '#E91E63'::character varying,
  recordatorio_minutos integer DEFAULT 15,
  es_recurrente boolean DEFAULT false,
  patron_recurrencia text,
  creado_por uuid,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT eventos_calendario_pkey PRIMARY KEY (id),
  CONSTRAINT eventos_calendario_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.profesores(id)
);
CREATE TABLE public.examenes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descripcion text,
  instrucciones text,
  fecha_disponible timestamp with time zone NOT NULL,
  fecha_limite timestamp with time zone NOT NULL,
  duracion_minutos integer DEFAULT 120,
  intentos_permitidos integer DEFAULT 1,
  puntos_maximos numeric DEFAULT 20.00,
  tipo_examen text DEFAULT 'parcial'::text CHECK (tipo_examen = ANY (ARRAY['parcial'::text, 'final'::text, 'practica'::text, 'quiz'::text])),
  mostrar_resultados boolean DEFAULT true,
  mostrar_respuestas boolean DEFAULT false,
  aleatorizar_preguntas boolean DEFAULT false,
  requiere_camara boolean DEFAULT false,
  estado text DEFAULT 'borrador'::text CHECK (estado = ANY (ARRAY['borrador'::text, 'publicado'::text, 'finalizado'::text])),
  fecha_creacion timestamp with time zone DEFAULT now(),
  curso_id uuid,
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  CONSTRAINT examenes_pkey PRIMARY KEY (id),
  CONSTRAINT examenes_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.examenes_entregas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  examen_id uuid,
  estudiante_id uuid,
  fecha_inicio timestamp with time zone DEFAULT now(),
  fecha_fin timestamp with time zone,
  calificacion numeric,
  intento integer NOT NULL,
  estado text NOT NULL,
  CONSTRAINT examenes_entregas_pkey PRIMARY KEY (id),
  CONSTRAINT examenes_entregas_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id),
  CONSTRAINT examenes_entregas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.facultades (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  codigo text NOT NULL UNIQUE,
  descripcion text,
  decano_nombre text,
  decano_email text,
  telefono text,
  direccion text,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT facultades_pkey PRIMARY KEY (id)
);
CREATE TABLE public.fechas_importantes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descripcion text,
  fecha_evento date NOT NULL,
  categoria text,
  CONSTRAINT fechas_importantes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.foros (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descripcion text,
  esta_bloqueado boolean DEFAULT false,
  creado_por uuid,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT foros_pkey PRIMARY KEY (id)
);
CREATE TABLE public.grupos_trabajo (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  descripcion text,
  tamaño_maximo integer DEFAULT 5,
  tipo_grupo text DEFAULT 'libre'::text CHECK (tipo_grupo = ANY (ARRAY['libre'::text, 'asignado'::text, 'aleatorio'::text])),
  proyecto_asociado text,
  fecha_limite_formacion date,
  estado text DEFAULT 'activo'::text CHECK (estado = ANY (ARRAY['activo'::text, 'cerrado'::text, 'finalizado'::text])),
  creado_por uuid,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT grupos_trabajo_pkey PRIMARY KEY (id),
  CONSTRAINT grupos_trabajo_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.profesores(id)
);
CREATE TABLE public.inscripciones_clase (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  estudiante_id uuid,
  fecha_inscripcion date DEFAULT CURRENT_DATE,
  estado text DEFAULT 'enrolled'::text CHECK (estado = ANY (ARRAY['enrolled'::text, 'dropped'::text, 'completed'::text])),
  calificacion_final numeric,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT inscripciones_clase_pkey PRIMARY KEY (id)
);
CREATE TABLE public.intentos_examenes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  examen_id uuid NOT NULL,
  estudiante_id uuid NOT NULL,
  numero_intento integer NOT NULL DEFAULT 1,
  fecha_inicio timestamp with time zone DEFAULT now(),
  fecha_finalizacion timestamp with time zone,
  puntos_obtenidos numeric,
  estado text DEFAULT 'en_progreso'::text CHECK (estado = ANY (ARRAY['en_progreso'::text, 'finalizado'::text, 'abandonado'::text])),
  respuestas jsonb,
  tiempo_empleado_minutos integer,
  CONSTRAINT intentos_examenes_pkey PRIMARY KEY (id),
  CONSTRAINT intentos_examenes_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES public.examenes(id),
  CONSTRAINT intentos_examenes_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.lecciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  unidad_curso_id uuid NOT NULL,
  titulo text NOT NULL,
  descripcion text,
  tipo_contenido text NOT NULL DEFAULT 'lectura'::text,
  contenido jsonb,
  duracion_minutos integer,
  orden_secuencial integer,
  es_obligatorio boolean DEFAULT true,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT lecciones_pkey PRIMARY KEY (id),
  CONSTRAINT lecciones_unidad_curso_id_fkey FOREIGN KEY (unidad_curso_id) REFERENCES public.unidades_curso(id)
);
CREATE TABLE public.lecturas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descripcion text,
  enlace_pdf text NOT NULL,
  CONSTRAINT lecturas_pkey PRIMARY KEY (id)
);
CREATE TABLE public.matriculas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  estudiante_id uuid NOT NULL,
  grupo_clase_id uuid,
  periodo_academico_id uuid NOT NULL,
  fecha_matricula timestamp with time zone DEFAULT now(),
  estado text DEFAULT 'matriculado'::text,
  nota_final numeric,
  fecha_retiro date,
  curso_id uuid,
  CONSTRAINT matriculas_pkey PRIMARY KEY (id),
  CONSTRAINT matriculas_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id),
  CONSTRAINT matriculas_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT matriculas_periodo_academico_id_fkey FOREIGN KEY (periodo_academico_id) REFERENCES public.periodos_academicos(id)
);
CREATE TABLE public.mensajes_chat (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversacion_id uuid NOT NULL,
  remitente_id uuid NOT NULL,
  tipo_remitente text DEFAULT 'estudiante'::text CHECK (tipo_remitente = ANY (ARRAY['estudiante'::text, 'profesor'::text, 'sistema'::text])),
  contenido text NOT NULL,
  tipo_mensaje text DEFAULT 'texto'::text CHECK (tipo_mensaje = ANY (ARRAY['texto'::text, 'imagen'::text, 'archivo'::text, 'sistema'::text])),
  archivos_adjuntos jsonb,
  mensaje_respondido_id uuid,
  editado boolean DEFAULT false,
  fecha_edicion timestamp with time zone,
  fecha_envio timestamp with time zone DEFAULT now(),
  CONSTRAINT mensajes_chat_pkey PRIMARY KEY (id),
  CONSTRAINT mensajes_chat_conversacion_id_fkey FOREIGN KEY (conversacion_id) REFERENCES public.conversaciones(id),
  CONSTRAINT mensajes_chat_mensaje_respondido_id_fkey FOREIGN KEY (mensaje_respondido_id) REFERENCES public.mensajes_chat(id)
);
CREATE TABLE public.mensajes_chat_grupal (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  estudiante_id uuid,
  contenido text NOT NULL CHECK (contenido <> ''::text),
  fecha_envio timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT mensajes_chat_grupal_pkey PRIMARY KEY (id),
  CONSTRAINT mensajes_chat_grupal_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id)
);
CREATE TABLE public.mensajes_foro (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  foro_id uuid,
  usuario_id uuid,
  contenido text NOT NULL,
  mensaje_padre_id uuid,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT mensajes_foro_pkey PRIMARY KEY (id),
  CONSTRAINT mensajes_foro_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES auth.users(id),
  CONSTRAINT mensajes_foro_foro_id_fkey FOREIGN KEY (foro_id) REFERENCES public.foros(id),
  CONSTRAINT mensajes_foro_mensaje_padre_id_fkey FOREIGN KEY (mensaje_padre_id) REFERENCES public.mensajes_foro(id)
);
CREATE TABLE public.mensajes_leidos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  mensaje_id uuid NOT NULL,
  usuario_id uuid NOT NULL,
  tipo_usuario text DEFAULT 'estudiante'::text CHECK (tipo_usuario = ANY (ARRAY['estudiante'::text, 'profesor'::text])),
  fecha_lectura timestamp with time zone DEFAULT now(),
  CONSTRAINT mensajes_leidos_pkey PRIMARY KEY (id),
  CONSTRAINT mensajes_leidos_mensaje_id_fkey FOREIGN KEY (mensaje_id) REFERENCES public.mensajes_chat(id)
);
CREATE TABLE public.miembros_grupos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  grupo_trabajo_id uuid NOT NULL,
  estudiante_id uuid NOT NULL,
  rol_grupo text DEFAULT 'miembro'::text CHECK (rol_grupo = ANY (ARRAY['lider'::text, 'miembro'::text, 'colaborador'::text])),
  fecha_union timestamp with time zone DEFAULT now(),
  CONSTRAINT miembros_grupos_pkey PRIMARY KEY (id),
  CONSTRAINT miembros_grupos_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT miembros_grupos_grupo_trabajo_id_fkey FOREIGN KEY (grupo_trabajo_id) REFERENCES public.grupos_trabajo(id)
);
CREATE TABLE public.participantes_conversacion (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversacion_id uuid NOT NULL,
  usuario_id uuid NOT NULL,
  tipo_usuario text DEFAULT 'estudiante'::text CHECK (tipo_usuario = ANY (ARRAY['estudiante'::text, 'profesor'::text, 'administrador'::text])),
  rol_conversacion text DEFAULT 'miembro'::text CHECK (rol_conversacion = ANY (ARRAY['administrador'::text, 'moderador'::text, 'miembro'::text])),
  silenciado boolean DEFAULT false,
  fecha_ultimo_acceso timestamp with time zone DEFAULT now(),
  fecha_union timestamp with time zone DEFAULT now(),
  CONSTRAINT participantes_conversacion_pkey PRIMARY KEY (id),
  CONSTRAINT participantes_conversacion_conversacion_id_fkey FOREIGN KEY (conversacion_id) REFERENCES public.conversaciones(id)
);
CREATE TABLE public.periodos_academicos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
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
CREATE TABLE public.profesores (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  codigo_profesor text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text,
  telefono text,
  especialidad text,
  grado_academico text,
  facultad_id uuid,
  estado text DEFAULT 'activo'::text,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  usuario_id uuid,
  CONSTRAINT profesores_pkey PRIMARY KEY (id),
  CONSTRAINT fk_profesores_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT profesores_facultad_id_fkey FOREIGN KEY (facultad_id) REFERENCES public.facultades(id)
);
CREATE TABLE public.progreso_estudiante (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  estudiante_id uuid NOT NULL,
  leccion_id uuid NOT NULL,
  completado boolean DEFAULT false,
  porcentaje_progreso integer DEFAULT 0,
  tiempo_empleado_minutos integer DEFAULT 0,
  fecha_inicio timestamp with time zone,
  fecha_completado timestamp with time zone,
  CONSTRAINT progreso_estudiante_pkey PRIMARY KEY (id),
  CONSTRAINT progreso_estudiante_estudiante_id_fkey FOREIGN KEY (estudiante_id) REFERENCES public.estudiantes(id),
  CONSTRAINT progreso_estudiante_leccion_id_fkey FOREIGN KEY (leccion_id) REFERENCES public.lecciones(id)
);
CREATE TABLE public.publicaciones_foro (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  foro_id uuid,
  autor_id uuid,
  publicacion_padre_id uuid,
  titulo text,
  contenido text NOT NULL,
  archivos_adjuntos jsonb,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  CONSTRAINT publicaciones_foro_pkey PRIMARY KEY (id),
  CONSTRAINT publicaciones_foro_foro_id_fkey FOREIGN KEY (foro_id) REFERENCES public.foros(id),
  CONSTRAINT publicaciones_foro_publicacion_padre_id_fkey FOREIGN KEY (publicacion_padre_id) REFERENCES public.publicaciones_foro(id)
);
CREATE TABLE public.tareas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descripcion text,
  instrucciones text,
  fecha_asignacion timestamp with time zone DEFAULT now(),
  fecha_entrega timestamp with time zone NOT NULL,
  puntos_maximos numeric DEFAULT 20.00,
  estado text DEFAULT 'activa'::text,
  curso_id uuid,
  CONSTRAINT tareas_pkey PRIMARY KEY (id),
  CONSTRAINT tareas_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.tareas_asignaciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
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
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  unidad_id uuid,
  titulo text NOT NULL,
  tipo text NOT NULL,
  icono text,
  orden integer,
  CONSTRAINT temas_unidad_pkey PRIMARY KEY (id),
  CONSTRAINT temas_unidad_unidad_id_fkey FOREIGN KEY (unidad_id) REFERENCES public.unidades(id)
);
CREATE TABLE public.unidades (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  curso_id uuid,
  numero_unidad integer NOT NULL,
  titulo text NOT NULL,
  descripcion text,
  CONSTRAINT unidades_pkey PRIMARY KEY (id),
  CONSTRAINT unidades_curso_id_fkey FOREIGN KEY (curso_id) REFERENCES public.cursos(id)
);
CREATE TABLE public.unidades_curso (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  curso_id uuid NOT NULL,
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
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  codigo_usuario text NOT NULL UNIQUE,
  contrasena_hash text NOT NULL,
  nombre_completo text NOT NULL,
  correo_electronico text UNIQUE,
  rol text NOT NULL CHECK (rol = ANY (ARRAY['admin'::text, 'profesor'::text, 'estudiante'::text])),
  activo boolean DEFAULT true,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT usuarios_pkey PRIMARY KEY (id)
);
CREATE TABLE public.videoconferencias (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titulo text NOT NULL,
  descripcion text,
  fecha_inicio timestamp with time zone NOT NULL,
  fecha_fin timestamp with time zone NOT NULL,
  enlace_reunion text NOT NULL,
  estado text DEFAULT 'programada'::text CHECK (estado = ANY (ARRAY['programada'::text, 'en_vivo'::text, 'finalizada'::text, 'cancelada'::text])),
  plataforma text DEFAULT 'google_meet'::text,
  requiere_grabacion boolean DEFAULT true,
  enlace_grabacion text,
  asistencia_requerida boolean DEFAULT true,
  fecha_creacion timestamp with time zone DEFAULT now(),
  CONSTRAINT videoconferencias_pkey PRIMARY KEY (id)
);
CREATE TABLE public.wiki_recursos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  grupo_clase_id uuid NOT NULL,
  titulo text NOT NULL,
  contenido text NOT NULL,
  tipo_recurso text DEFAULT 'wiki'::text CHECK (tipo_recurso = ANY (ARRAY['wiki'::text, 'documento'::text, 'enlace'::text, 'video'::text])),
  categoria text,
  etiquetas ARRAY,
  archivo_adjunto text,
  enlace_externo text,
  es_publico boolean DEFAULT true,
  permite_comentarios boolean DEFAULT true,
  creado_por uuid,
  fecha_creacion timestamp with time zone DEFAULT now(),
  fecha_actualizacion timestamp with time zone DEFAULT now(),
  CONSTRAINT wiki_recursos_pkey PRIMARY KEY (id),
  CONSTRAINT wiki_recursos_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.profesores(id)
);