// lib/core/models/catalog_models.dart

class Tournament {
  final int id;
  final String name;
  final String category;

  Tournament({required this.id, required this.name, required this.category});

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      category: json['category'] ?? '',
    );
  }

  get status => null;
}

class TournamentTeamRelation {
  final int tournamentId;
  final int teamId;
  TournamentTeamRelation({required this.tournamentId, required this.teamId});
  
  factory TournamentTeamRelation.fromJson(Map<String, dynamic> json) {
    return TournamentTeamRelation(
      tournamentId: int.parse(json['tournament_id'].toString()),
      teamId: int.parse(json['team_id'].toString()),
    );
  }
}

class Venue {
  final int id;
  final String name;
  final String address;

  Venue({required this.id, required this.name, required this.address});

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      address: json['address'] ?? '',
    );
  }
}

class Team {
  final int id;
  final String name;
  final String shortName;
  final String coachName;
  final String? logoUrl;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.coachName,
    this.logoUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      shortName: json['short_name'] ?? '',
      coachName: json['coach_name'] ?? '',
      logoUrl: json['logo_url'],
    );
  }
}

class Player {
  final int id;
  final int teamId;
  final String name;
  final int defaultNumber;

  Player({
    required this.id,
    required this.teamId,
    required this.name,
    required this.defaultNumber,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: int.parse(json['id'].toString()),
      teamId: int.parse(json['team_id'].toString()),
      name: json['name'],
      defaultNumber: int.tryParse(json['default_number'].toString()) ?? 0,
    );
  }
}

// Clase contenedora para recibir todo de golpe
class CatalogData {
  final List<Tournament> tournaments;
  final List<Venue> venues;
  final List<Team> teams;
  final List<Player> players;
  final List<TournamentTeamRelation> relationships; 
  final List<dynamic> fixturesRaw;

  CatalogData({
    required this.tournaments,
    required this.venues,
    required this.teams,
    required this.players,
    required this.relationships,
    this.fixturesRaw = const [],
  });
}