import 'package:equatable/equatable.dart';
import '../auth_service.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state while app is booting and checking saved session
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// In-progress state (e.g. logging in or verifying token)
class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// User is successfully logged in and ready on a specific branch
class Authenticated extends AuthState {
  final AuthUser user;
  final String? activeLocationName;

  const Authenticated({
    required this.user,
    this.activeLocationName,
  });

  @override
  List<Object?> get props => [user, activeLocationName];
}

/// User has logged in, but needs to pick an outlet from multiple branches
class AuthBranchSelectionRequired extends AuthState {
  final AuthUser user;

  const AuthBranchSelectionRequired({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is not logged in or has logged out
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication failed
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
