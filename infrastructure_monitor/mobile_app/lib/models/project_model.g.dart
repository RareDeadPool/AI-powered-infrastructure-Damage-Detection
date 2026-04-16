// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      isSynced: fields[3] as bool,
      userId: fields[4] as String,
      location: fields[5] as String,
      reportPdfPath: fields[6] as String?,
      reportPdfUrl: fields[7] as String?,
      detectionCount: fields[8] as int,
      isDeleted: fields[9] as bool,
      updatedAt: fields[10] as DateTime?,
      isCorrect: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.isSynced)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.reportPdfPath)
      ..writeByte(7)
      ..write(obj.reportPdfUrl)
      ..writeByte(8)
      ..write(obj.detectionCount)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.isCorrect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
