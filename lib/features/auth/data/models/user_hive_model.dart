// import 'package:hive/hive.dart';
// import 'package:uuid/uuid.dart';
// import 'package:lost_n_found/core/constants/hive_table_constant.dart';
// import '../../domain/entities/user_entity.dart';

// part 'user_hive_model.g.dart';

// @HiveType(typeId: HiveTableConstant.userTypeId)
// class UserHiveModel extends HiveObject {
//   @HiveField(0)
//   final String userId;

//   @HiveField(1)
//   final String name;

//   @HiveField(2)
//   final String email;

//   @HiveField(3)
//   final String phone;

//   @HiveField(4)
//   final String password;

//   UserHiveModel({
//     String? userId,
//     required this.name,
//     required this.email,
//     required this.phone,
//     required this.password,
//   }) : userId = userId ?? const Uuid().v4();

//   UserEntity toEntity() {
//     return UserEntity(
//       userId: userId,
//       name: name,
//       email: email,
//       phone: phone,
//       password: password,
//     );
//   }

//   factory UserHiveModel.fromEntity(UserEntity entity) {
//     return UserHiveModel(
//       userId: entity.userId,
//       name: entity.name,
//       email: entity.email,
//       phone: entity.phone,
//       password: entity.password,
//     );
//   }
// }
