import '../models/pharmacy_company.dart';
import '../models/pharmacy_branch.dart';
import '../models/inventory_item.dart';
import '../models/medicine.dart';
import '../models/note.dart';
import 'database_helper.dart';

class SqliteService {
  static Future<List<PharmacyCompany>> fetchCompanies() async {
    return DatabaseHelper.instance.getCompanies();
  }

  static Future<List<PharmacyBranch>> fetchBranches() async {
    return DatabaseHelper.instance.getBranches();
  }

  static Future<List<InventoryItem>> fetchInventory() async {
    return DatabaseHelper.instance.getInventory();
  }

  static Future<int> ensureUser(String email, String displayName) {
    return DatabaseHelper.instance.createUserIfMissing(email, displayName);
  }

  static Future<List<Note>> fetchNotes(int userId) {
    return DatabaseHelper.instance.getNotesByUser(userId);
  }

  static Future<Note> addNote(Note note) {
    return DatabaseHelper.instance.insertNote(note);
  }

  static Future<int> removeNote(String id) {
    return DatabaseHelper.instance.deleteNote(id);
  }

  static Future<bool> toggleFavorite(int userId, int medicineId) {
    return DatabaseHelper.instance.toggleFavorite(userId, medicineId);
  }

  static Future<bool> isFavorite(int userId, int medicineId) {
    return DatabaseHelper.instance.isFavorite(userId, medicineId);
  }

  static Future<List<Medicine>> fetchFavoriteMedicines(int userId) {
    return DatabaseHelper.instance.getFavoriteMedicines(userId);
  }
}
