import 'dart:typed_data';

class User {
  final int id;
  String name;
  Uint8List? avatar;

  User({required this.id, required this.name, this.avatar});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar
    };
  }

  static User fromMap(Map map) {
    return User(
      id: map['id'], 
      name: map['name'],
      avatar: map['avatar']
    );
  }
}

class Debt {
  final int id;
  String title;
  String? description;
  final DateTime date;

  Debt({required this.id, required this.title, this.description, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': description,
      'description': description,
      'date': date.toIso8601String()
    };
  }

  static Debt fromMap(Map map) {
    return Debt(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date'])
    );
  }
}

class Debtor {
  final int debtId;
  final int userId;
  int amount; // amount owed in total

  Debtor({required this.debtId, required this.userId, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'debtId': debtId,
      'userId': userId,
      'amount': amount
    };
  }

  static Debtor fromMap(Map map) {
    return Debtor(
      debtId: map['debtId'],
      userId: map['userId'],
      amount: map['amount']
    );
  }
}

class Payment {
  final int id;
  final int userId;
  int amount;
  String? description;
  final DateTime date;

  Payment({required this.id, required this.userId, required this.amount, this.description, required this.date});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "amount": amount,
      "description": description,
      "date": date.toIso8601String()
    };
  }

  static Payment fromMap(Map map) {
    return Payment(
      id: map['id'],
      userId: map['userId'],
      amount: map['amount'],
      description: map['description'],
      date: DateTime.parse(map['date'])
    );
  }
}