class Account {
  final String id;
  final String name;
  final String? email;
  final String? googleId;
  final DateTime createdAt;
  final DateTime lastAccessed;
  final bool isLocal;
  final bool hasGoogleBackup;

  Account({
    required this.id,
    required this.name,
    this.email,
    this.googleId,
    required this.createdAt,
    required this.lastAccessed,
    this.isLocal = true,
    this.hasGoogleBackup = false,
  });

  Account copyWith({
    String? id,
    String? name,
    String? email,
    String? googleId,
    DateTime? createdAt,
    DateTime? lastAccessed,
    bool? isLocal,
    bool? hasGoogleBackup,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      googleId: googleId ?? this.googleId,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isLocal: isLocal ?? this.isLocal,
      hasGoogleBackup: hasGoogleBackup ?? this.hasGoogleBackup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'googleId': googleId,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'isLocal': isLocal,
      'hasGoogleBackup': hasGoogleBackup,
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      googleId: json['googleId'],
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessed: DateTime.parse(json['lastAccessed']),
      isLocal: json['isLocal'] ?? true,
      hasGoogleBackup: json['hasGoogleBackup'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, name: $name, email: $email, isLocal: $isLocal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

