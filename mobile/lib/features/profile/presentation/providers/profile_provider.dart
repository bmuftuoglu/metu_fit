import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/models/user_model.dart';

final profileDatasourceProvider = Provider((_) => ProfileRemoteDatasource());

final profileProvider = FutureProvider<UserModel>((ref) {
  return ref.read(profileDatasourceProvider).getProfile();
});
