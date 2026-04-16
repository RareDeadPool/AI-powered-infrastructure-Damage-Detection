// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DetectionAdapter extends TypeAdapter<Detection> {
  @override
  final int typeId = 1;

  @override
  Detection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Detection(
      id: fields[0] as String,
      projectId: fields[1] as String,
      imagePath: fields[2] as String,
      imageUrl: fields[3] as String?,
      damageType: fields[4] as String,
      severity: fields[5] as String,
      confidence: fields[6] as double,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
      timestamp: fields[9] as DateTime,
      isDeleted: fields[10] as bool,
      updatedAt: fields[11] as DateTime?,
      isSynced: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Detection obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.damageType)
      ..writeByte(5)
      ..write(obj.severity)
      ..writeByte(6)
      ..write(obj.confidence)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.timestamp)
      ..writeByte(10)
      ..write(obj.isDeleted)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
