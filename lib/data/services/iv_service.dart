import 'dart:convert';
import 'package:http/http.dart' as http;

class DrugInteraction {
  final String drug1;
  final String drug2;
  final String severity;
  final String description;
  DrugInteraction({required this.drug1, required this.drug2, required this.severity, required this.description});
}

class IvService {
  static const String _baseUrl = 'https://rxnav.nlm.nih.gov/REST';

  // البحث عن RxCUI للدواء
  Future<String?> getRxcui(String drugName) async {
    try {
      final url = Uri.parse('$_baseUrl/rxcui.json?name=$drugName&search=1');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final idGroup = data['idGroup'];
        if (idGroup != null && idGroup['rxnormId'] != null) {
          final ids = idGroup['rxnormId'] as List;
          if (ids.isNotEmpty) return ids.first.toString();
        }
      }
    } catch (e) {
      print('RxCUI error: $e');
    }
    return null;
  }

  // فحص التداخل بين دوائين - ONLINE IV CHECKER
  Future<List<DrugInteraction>> checkInteraction(String drugA, String drugB) async {
    final rxcuiA = await getRxcui(drugA);
    final rxcuiB = await getRxcui(drugB);

    if (rxcuiA == null || rxcuiB == null) {
      throw Exception('لم يتم العثور على أحد الأدوية في قاعدة RxNav');
    }

    final url = Uri.parse('$_baseUrl/interaction/list.json?rxcuis=$rxcuiA+$rxcuiB');
    final res = await http.get(url);

    if (res.statusCode != 200) throw Exception('فشل الاتصال بـ RxNav');

    final data = json.decode(res.body);
    final interactions = <DrugInteraction>[];

    try {
      final fullType = data['fullInteractionTypeGroup'];
      if (fullType == null || (fullType as List).isEmpty) return []; // لا يوجد تداخل

      for (var group in fullType) {
        final types = group['fullInteractionType'] as List?;
        if (types == null) continue;
        for (var type in types) {
          final pairs = type['interactionPair'] as List?;
          if (pairs == null) continue;
          for (var pair in pairs) {
            interactions.add(DrugInteraction(
              drug1: pair['interactionConcept'][0]['minConceptItem']['name'] ?? drugA,
              drug2: pair['interactionConcept'][1]['minConceptItem']['name'] ?? drugB,
              severity: pair['severity'] ?? 'unknown',
              description: pair['description'] ?? 'يوجد تداخل محتمل، راجع الصيدلي',
            ));
          }
        }
      }
    } catch (e) {
      print('Parse error: $e');
    }

    return interactions;
  }

  // فحص IV compatibility محلي سريع (قاعدة بيانات مبسطة)
  bool isIvCompatible(String drug1, String drug2) {
    const incompatibilities = {
      'ceftriaxone': ['calcium', 'ringer'],
      'phenytoin': ['dextrose', 'glucose'],
      'diazepam': ['ns', 'normal saline'],
    };
    final d1 = drug1.toLowerCase();
    final d2 = drug2.toLowerCase();
    for (var entry in incompatibilities.entries) {
      if ((d1.contains(entry.key) && entry.value.any((x) => d2.contains(x))) ||
          (d2.contains(entry.key) && entry.value.any((x) => d1.contains(x)))) {
        return false;
      }
    }
    return true;
  }
}

