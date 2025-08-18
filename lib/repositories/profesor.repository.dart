import 'package:aulago/models/profesor.model.dart';
import 'package:aulago/repositories/base.repository.dart';

class ProfesorRepository extends BaseRepository<ProfesorAdmin> {
  @override
  String get tableName => 'profesores';
  
  @override
  String get repositoryName => 'ProfesorRepository';
  
  @override
  ProfesorAdmin fromJson(Map<String, dynamic> json) {
    return ProfesorAdmin.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(ProfesorAdmin entity) {
    return entity.toJson();
  }

  @override
  String getId(ProfesorAdmin entity) {
    return entity.id.toString();
  }

  // CRUD básico
  Future<List<ProfesorAdmin>> obtenerProfesores() async {
    try {
      // Preferido: incluir joins (usuarios, facultades)
      final response = await supabase
          .from(tableName)
          .select('*, usuarios:usuarios!fk_profesores_usuario(*), facultades:facultades!profesores_facultad_id_fkey(nombre)')
          .limit(1000);
      return List<Map<String, dynamic>>.from(response)
          .map(ProfesorAdmin.fromJson)
          .toList();
    } catch (_) {
      // Fallback: sin join a facultades (evita permisos faltantes)
      final response = await supabase
          .from(tableName)
          .select('*, usuarios:usuarios!fk_profesores_usuario(*)')
          .limit(1000);
      return List<Map<String, dynamic>>.from(response)
          .map(ProfesorAdmin.fromJson)
          .toList();
    }
  }

  Future<ProfesorAdmin?> obtenerProfesorPorId(int id) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('*, usuarios:usuarios!fk_profesores_usuario(*), facultades:facultades!profesores_facultad_id_fkey(nombre)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return ProfesorAdmin.fromJson(response);
    } catch (_) {
      final response = await supabase
          .from(tableName)
          .select('*, usuarios:usuarios!fk_profesores_usuario(*)')
          .eq('id', id)
          .maybeSingle();
      if (response == null) {
        return null;
      }
      return ProfesorAdmin.fromJson(response);
    }
  }

  /// Obtiene el id del profesor a partir del usuario_id (tabla usuarios)
  Future<int?> obtenerProfesorIdPorUsuarioId(int usuarioId) async {
    final resp = await supabase
        .from(tableName)
        .select('id')
        .eq('usuario_id', usuarioId)
        .maybeSingle();
    if (resp == null || resp['id'] == null) {
      return null;
    }
    return (resp['id'] as num).toInt();
  }

  Future<ProfesorAdmin> crearProfesor(ProfesorAdmin profesor, {required String contrasena}) async {
    // Construir payload conforme a columnas NOT NULL en 'profesores'
    final data = <String, dynamic>{
      'codigo_profesor': profesor.usuario.codigoUsuario,
      'nombre_completo': profesor.usuario.nombreCompleto,
      'correo_electronico': profesor.usuario.correoElectronico,
      'contrasena_hash': contrasena,
      'usuario_id': (profesor.usuario.id > 0) ? profesor.usuario.id : null,
      'especialidad': profesor.especialidad,
      'grado_academico': profesor.gradoAcademico,
      'facultad_id': profesor.facultadId == null ? null : int.tryParse(profesor.facultadId!),
      'estado': profesor.estado,
      'fecha_creacion': profesor.fechaCreacion.toIso8601String(),
      'fecha_actualizacion': profesor.fechaActualizacion.toIso8601String(),
      'foto_perfil_url': profesor.usuario.fotoPerfilUrl,
    };
    return crear(data);
  }

  Future<ProfesorAdmin> actualizarProfesor(int id, ProfesorAdmin profesor) async {
    return actualizar(id.toString(), profesor.toJson());
  }

  Future<bool> eliminarProfesor(int id) async {
    await eliminar(id.toString());
    return true;
  }

  /// Obtiene los cursos que dicta un profesor, con datos de carrera y conteo de matriculados
  Future<List<CursoProfesor>> obtenerCursosPorProfesor(int profesorId) async {
    // 1) Traer cursos con datos de carrera
    final cursosResp = await supabase
        .from('cursos')
        .select('id, codigo_curso, nombre, creditos, carreras(nombre)')
        .eq('profesor_id', profesorId);

    final cursos = List<Map<String, dynamic>>.from(cursosResp);

    // 2) Obtener conteo de matriculados por curso (una sola llamada agrupada)
    final ids = cursos.map((c) => c['id']).toList();
    final Map<int, int> cursoIdToCount = {};
    if (ids.isNotEmpty) {
      final matriculasResp = await supabase
          .from('matriculas')
          .select('curso_id')
          .inFilter('curso_id', ids);
      // Contar en cliente
      for (final row in List<Map<String, dynamic>>.from(matriculasResp)) {
        final cid = (row['curso_id'] as num).toInt();
        cursoIdToCount[cid] = (cursoIdToCount[cid] ?? 0) + 1;
      }
    }

    // 3) Mapear a modelo
    return cursos.map((c) {
      final cursoId = (c['id'] as num).toInt();
      return CursoProfesor(
        cursoId: cursoId.toString(),
        codigoCurso: c['codigo_curso']?.toString() ?? '',
        nombreCurso: c['nombre']?.toString() ?? '',
        creditos: (c['creditos'] as num?)?.toInt() ?? 0,
        carreraNombre: (c['carreras'] as Map<String, dynamic>?)?['nombre']?.toString(),
        estudiantesMatriculados: cursoIdToCount[cursoId] ?? 0,
      );
    }).toList();
  }

  /// Actualiza contraseña en profesores y usuarios
  Future<void> actualizarContrasena({
    required int profesorId,
    required String nuevaContrasena,
    int? usuarioId,
  }) async {
    // profesores
    await supabase
        .from('profesores')
        .update({'contrasena_hash': nuevaContrasena})
        .eq('id', profesorId);

    // usuarios (si existe)
    if (usuarioId != null) {
      await supabase
          .from('usuarios')
          .update({'contrasena_hash': nuevaContrasena})
          .eq('id', usuarioId);
    } else {
      final resp = await supabase
          .from('profesores')
          .select('usuario_id')
          .eq('id', profesorId)
          .maybeSingle();
      final uid = resp != null && resp['usuario_id'] != null
          ? int.tryParse(resp['usuario_id'].toString())
          : null;
      if (uid != null) {
        await supabase
            .from('usuarios')
            .update({'contrasena_hash': nuevaContrasena})
            .eq('id', uid);
      }
    }
  }

  /// Actualiza información del profesor (profesores + usuarios)
  Future<void> actualizarPerfil({
    required int profesorId,
    required int usuarioId,
    required String codigoUsuario,
    required String nombreCompleto,
    required String correoElectronico,
    required bool activo,
    String? telefono,
    String? especialidad,
    String? gradoAcademico,
    int? facultadId,
    String? estado,
  }) async {
    // Actualizar usuarios
    await supabase
        .from('usuarios')
        .update({
          'codigo_usuario': codigoUsuario,
          'nombre_completo': nombreCompleto,
          'correo_electronico': correoElectronico,
          'activo': activo,
        })
        .eq('id', usuarioId);

    // Actualizar profesores
    await supabase
        .from('profesores')
        .update({
          'telefono': telefono,
          'especialidad': especialidad,
          'grado_academico': gradoAcademico,
          'facultad_id': facultadId,
          'estado': estado,
          'fecha_actualizacion': DateTime.now().toIso8601String(),
        })
        .eq('id', profesorId);
  }

  /// Actualiza contraseña para profesor buscando por código de profesor
  Future<void> actualizarContrasenaPorCodigo({
    required String codigoProfesor,
    required String nuevaContrasena,
  }) async {
    // profesores (si existe columna codigo_profesor)
    await supabase
        .from('profesores')
        .update({'contrasena_hash': nuevaContrasena})
        .eq('codigo_profesor', codigoProfesor);

    // usuarios por código_usuario
    await supabase
        .from('usuarios')
        .update({'contrasena_hash': nuevaContrasena})
        .eq('codigo_usuario', codigoProfesor);
  }
}
