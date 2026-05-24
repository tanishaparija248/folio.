import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class AddFolder extends DashboardEvent {
  final String name;
  const AddFolder(this.name);

  @override
  List<Object> get props => [name];
}

class DeleteDocument extends DashboardEvent {
  final int id;
  const DeleteDocument(this.id);

  @override
  List<Object> get props => [id];
}

class DeleteFolder extends DashboardEvent {
  final int id;
  const DeleteFolder(this.id);

  @override
  List<Object> get props => [id];
}

// ✅ NEW: Rename Folder
class RenameFolder extends DashboardEvent {
  final int id;
  final String newName;

  const RenameFolder(this.id, this.newName);

  @override
  List<Object> get props => [id, newName];
}

// ✅ NEW: Rename Document
class RenameDocument extends DashboardEvent {
  final int id;
  final String newName;

  const RenameDocument(this.id, this.newName);

  @override
  List<Object> get props => [id, newName];
}