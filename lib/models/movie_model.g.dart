// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'movie_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MovieAdapter extends TypeAdapter<Movie> {
  @override
  final int typeId = 0;

  @override
  Movie read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Movie(
      id: fields[0] as String,
      title: fields[1] as String,
      posterPath: fields[2] as String?,
      backdropPath: fields[3] as String?,
      overview: fields[4] as String?,
      releaseDate: fields[5] as String?,
      voteAverage: fields[6] as double?,
      genres: (fields[7] as List).cast<String>(),
      languages: (fields[8] as List).cast<String>(),
      runtime: fields[9] as int?,
      isMovie: fields[10] as bool,
      imdbId: fields[11] as String?,
      year: fields[12] as int?,
      trailerKey: fields[13] as String?,
      status: fields[14] as String?,
      availableProviders: (fields[15] as List).cast<String>(),
      streamSources: (fields[16] as List).cast<StreamSource>(),
      tagline: fields[17] as String?,
      voteCount: fields[18] as int?,
      cast: (fields[19] as List).cast<CastMember>(),
    );
  }

  @override
  void write(BinaryWriter writer, Movie obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.posterPath)
      ..writeByte(3)
      ..write(obj.backdropPath)
      ..writeByte(4)
      ..write(obj.overview)
      ..writeByte(5)
      ..write(obj.releaseDate)
      ..writeByte(6)
      ..write(obj.voteAverage)
      ..writeByte(7)
      ..write(obj.genres)
      ..writeByte(8)
      ..write(obj.languages)
      ..writeByte(9)
      ..write(obj.runtime)
      ..writeByte(10)
      ..write(obj.isMovie)
      ..writeByte(11)
      ..write(obj.imdbId)
      ..writeByte(12)
      ..write(obj.year)
      ..writeByte(13)
      ..write(obj.trailerKey)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.availableProviders)
      ..writeByte(16)
      ..write(obj.streamSources)
      ..writeByte(17)
      ..write(obj.tagline)
      ..writeByte(18)
      ..write(obj.voteCount)
      ..writeByte(19)
      ..write(obj.cast);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StreamSourceAdapter extends TypeAdapter<StreamSource> {
  @override
  final int typeId = 1;

  @override
  StreamSource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreamSource(
      providerName: fields[0] as String,
      url: fields[1] as String,
      quality: fields[2] as String,
      subtitle: fields[3] as String?,
      isWorking: fields[4] as bool,
      lastChecked: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StreamSource obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.providerName)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.quality)
      ..writeByte(3)
      ..write(obj.subtitle)
      ..writeByte(4)
      ..write(obj.isWorking)
      ..writeByte(5)
      ..write(obj.lastChecked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CastMemberAdapter extends TypeAdapter<CastMember> {
  @override
  final int typeId = 2;

  @override
  CastMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CastMember(
      name: fields[0] as String,
      character: fields[1] as String?,
      profilePath: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CastMember obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.character)
      ..writeByte(2)
      ..write(obj.profilePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CastMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WatchHistoryEntryAdapter extends TypeAdapter<WatchHistoryEntry> {
  @override
  final int typeId = 3;

  @override
  WatchHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchHistoryEntry(
      movieId: fields[0] as String,
      movieTitle: fields[1] as String,
      posterPath: fields[2] as String?,
      progressSeconds: fields[3] as int,
      totalSeconds: fields[4] as int,
      lastWatched: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WatchHistoryEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.movieId)
      ..writeByte(1)
      ..write(obj.movieTitle)
      ..writeByte(2)
      ..write(obj.posterPath)
      ..writeByte(3)
      ..write(obj.progressSeconds)
      ..writeByte(4)
      ..write(obj.totalSeconds)
      ..writeByte(5)
      ..write(obj.lastWatched);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
