import '/domain/entities/candidate.dart';

abstract class CandidateRepository {
  Future<List<Candidate>> getCandidates();
  Future<void> syncCandidates();
  Future<List<Candidate>> searchCandidates(String query);
}
