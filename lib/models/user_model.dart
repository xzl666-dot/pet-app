class User {
  final int? id;
  final int? userId;
  final String? username;
  final String nickname;
  final String? avatar;
  final String? phone;
  final String? password;
  final String? passwordHash;
  final String? token;
  final DateTime? tokenExpire;
  final bool isAdmin;
  final bool isOnline;
  final int isVip;
  final DateTime? vipExpire;
  final int versionType;
  final DateTime createTime;
  final DateTime lastLoginTime;
  final int? challengeWin;
  final int? challengeLose;
  final int? challengeScore;
  final String? manualState;
  final DateTime? manualStateExpire;
  final int? petId;

  User({
    this.id,
    this.userId,
    this.username,
    required this.nickname,
    this.avatar,
    this.phone,
    this.password,
    this.passwordHash,
    this.token,
    this.tokenExpire,
    this.isAdmin = false,
    this.isOnline = false,
    this.isVip = 0,
    this.vipExpire,
    this.versionType = 0,
    required this.createTime,
    required this.lastLoginTime,
    this.challengeWin,
    this.challengeLose,
    this.challengeScore,
    this.manualState,
    this.manualStateExpire,
    this.petId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
      'password': password,
      'passwordHash': passwordHash,
      'token': token,
      'tokenExpire': tokenExpire?.toIso8601String(),
      'isAdmin': isAdmin ? 1 : 0,
      'isOnline': isOnline ? 1 : 0,
      'isVip': isVip,
      'vipExpire': vipExpire?.toIso8601String(),
      'versionType': versionType,
      'createTime': createTime.toIso8601String(),
      'lastLoginTime': lastLoginTime.toIso8601String(),
      'challengeWin': challengeWin,
      'challengeLose': challengeLose,
      'challengeScore': challengeScore,
      'manualState': manualState,
      'manualStateExpire': manualStateExpire?.toIso8601String(),
      'petId': petId,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      userId: map['userId'] ?? map['id'],
      username: map['username'],
      nickname: map['nickname'] ?? '萌宠主人',
      avatar: map['avatar'],
      phone: map['phone'],
      password: map['password'],
      passwordHash: map['passwordHash'],
      token: map['token'],
      tokenExpire: map['tokenExpire'] != null ? DateTime.parse(map['tokenExpire']) : null,
      isAdmin: map['isAdmin'] == 1 || map['isAdmin'] == true,
      isOnline: map['isOnline'] == 1 || map['isOnline'] == true,
      isVip: map['isVip'] ?? 0,
      vipExpire: map['vipExpire'] != null ? DateTime.parse(map['vipExpire']) : null,
      versionType: map['versionType'] ?? 0,
      createTime: map['createTime'] != null ? DateTime.parse(map['createTime']) : DateTime.now(),
      lastLoginTime: map['lastLoginTime'] != null ? DateTime.parse(map['lastLoginTime']) : DateTime.now(),
      challengeWin: map['challengeWin'],
      challengeLose: map['challengeLose'],
      challengeScore: map['challengeScore'],
      manualState: map['manualState'],
      manualStateExpire: map['manualStateExpire'] != null ? DateTime.parse(map['manualStateExpire']) : null,
      petId: map['petId'],
    );
  }

  User copyWith({
    int? id,
    int? userId,
    String? username,
    String? nickname,
    String? avatar,
    String? phone,
    String? password,
    String? passwordHash,
    String? token,
    DateTime? tokenExpire,
    bool? isAdmin,
    bool? isOnline,
    int? isVip,
    DateTime? vipExpire,
    int? versionType,
    DateTime? createTime,
    DateTime? lastLoginTime,
    int? challengeWin,
    int? challengeLose,
    int? challengeScore,
    String? manualState,
    DateTime? manualStateExpire,
    int? petId,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      passwordHash: passwordHash ?? this.passwordHash,
      token: token ?? this.token,
      tokenExpire: tokenExpire ?? this.tokenExpire,
      isAdmin: isAdmin ?? this.isAdmin,
      isOnline: isOnline ?? this.isOnline,
      isVip: isVip ?? this.isVip,
      vipExpire: vipExpire ?? this.vipExpire,
      versionType: versionType ?? this.versionType,
      createTime: createTime ?? this.createTime,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
      challengeWin: challengeWin ?? this.challengeWin,
      challengeLose: challengeLose ?? this.challengeLose,
      challengeScore: challengeScore ?? this.challengeScore,
      manualState: manualState ?? this.manualState,
      manualStateExpire: manualStateExpire ?? this.manualStateExpire,
      petId: petId ?? this.petId,
    );
  }
}
