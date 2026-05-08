import 'package:flutter/material.dart';
import '../../data/models/ride_model.dart';
import '../../data/repositories/ride_repository.dart';

class RideViewModel extends ChangeNotifier {
  final RideRepository _repo;
  RideViewModel(this._repo);

  // ── Feed ──────────────────────────────────────────────────────────────────
  List<RideModel> rides = [];
  String? _nextCursor;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  // Filters
  String? filterType; // null = all, "find", "offer"
  String? filterFromId;
  String? filterToId;

  Future<void> loadRides({bool refresh = false}) async {
    if (refresh) {
      rides = [];
      _nextCursor = null;
      hasMore = true;
      errorMessage = null;
    }
    if (!hasMore) return;
    if (refresh) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }
    notifyListeners();

    final result = await _repo.getRides(
      cursor: _nextCursor,
      type: filterType,
      fromId: filterFromId,
      toId: filterToId,
    );
    isLoading = false;
    isLoadingMore = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      rides = refresh
          ? result.data!.rides
          : [...rides, ...result.data!.rides];
      _nextCursor = result.data!.nextCursor;
      hasMore = _nextCursor != null;
    }
    notifyListeners();
  }

  void setFilter({String? type, String? fromId, String? toId}) {
    filterType = type;
    filterFromId = fromId;
    filterToId = toId;
    loadRides(refresh: true);
  }

  void clearFilters() {
    filterType = null;
    filterFromId = null;
    filterToId = null;
    loadRides(refresh: true);
  }

  // ── My Rides ──────────────────────────────────────────────────────────────
  List<RideModel> myRides = [];
  String? _myNextCursor;
  bool isLoadingMy = false;
  bool hasMoreMy = true;

  Future<void> loadMyRides({bool refresh = false}) async {
    if (refresh) {
      myRides = [];
      _myNextCursor = null;
      hasMoreMy = true;
    }
    if (!hasMoreMy) return;
    isLoadingMy = true;
    notifyListeners();

    final result = await _repo.getMyRides(cursor: _myNextCursor);
    isLoadingMy = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      myRides = refresh
          ? result.data!.rides
          : [...myRides, ...result.data!.rides];
      _myNextCursor = result.data!.nextCursor;
      hasMoreMy = _myNextCursor != null;
    }
    notifyListeners();
  }

  // ── Joined Rides ──────────────────────────────────────────────────────────
  List<RideModel> joinedRides = [];
  String? _joinedNextCursor;
  bool isLoadingJoined = false;
  bool hasMoreJoined = true;

  Future<void> loadJoinedRides({bool refresh = false}) async {
    if (refresh) {
      joinedRides = [];
      _joinedNextCursor = null;
      hasMoreJoined = true;
    }
    if (!hasMoreJoined) return;
    isLoadingJoined = true;
    notifyListeners();

    final result = await _repo.getJoinedRides(cursor: _joinedNextCursor);
    isLoadingJoined = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      joinedRides = refresh
          ? result.data!.rides
          : [...joinedRides, ...result.data!.rides];
      _joinedNextCursor = result.data!.nextCursor;
      hasMoreJoined = _joinedNextCursor != null;
    }
    notifyListeners();
  }

  // ── Detail ────────────────────────────────────────────────────────────────
  RideModel? currentRide;
  bool isLoadingDetail = false;
  List<RideModel> matchedRides = [];
  List<RideRequestModel> rideRequests = [];

  Future<void> loadRideDetail(String id) async {
    isLoadingDetail = true;
    matchedRides = [];
    rideRequests = [];
    notifyListeners();

    final result = await _repo.getRideById(id);
    isLoadingDetail = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      currentRide = result.data;
      // Load matches in parallel
      _loadMatches(id);
    }
    notifyListeners();
  }

  Future<void> _loadMatches(String id) async {
    final result = await _repo.getMatchedRides(id);
    if (result.failure == null) {
      matchedRides = result.data!;
      notifyListeners();
    }
  }

  Future<void> loadRideRequests(String rideId) async {
    final result = await _repo.getRideRequests(rideId);
    if (result.failure == null) {
      rideRequests = result.data!;
      notifyListeners();
    }
  }

  // ── My Requests ───────────────────────────────────────────────────────────
  List<RideRequestModel> myRequests = [];
  bool isLoadingMyRequests = false;

  Future<void> loadMyRideRequests() async {
    isLoadingMyRequests = true;
    notifyListeners();

    final result = await _repo.getMyRideRequests();
    isLoadingMyRequests = false;

    if (result.failure == null) {
      myRequests = result.data!;
    }
    notifyListeners();
  }

  // ── Create ────────────────────────────────────────────────────────────────
  bool isCreating = false;

  Future<RideModel?> createRide(Map<String, dynamic> body) async {
    isCreating = true;
    notifyListeners();

    final result = await _repo.createRide(body);
    isCreating = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return null;
    }
    rides = [result.data!, ...rides];
    myRides = [result.data!, ...myRides];
    notifyListeners();
    return result.data;
  }

  // ── Request Join ──────────────────────────────────────────────────────────
  bool isSendingRequest = false;
  // rideId → request status for current user
  final Map<String, RideRequestModel> _myRequestMap = {};

  RideRequestModel? myRequestFor(String rideId) => _myRequestMap[rideId];

  Future<bool> requestJoinRide(String rideId, {String? message}) async {
    isSendingRequest = true;
    notifyListeners();

    final result = await _repo.requestJoinRide(rideId, message);
    isSendingRequest = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    _myRequestMap[rideId] = result.data!;
    notifyListeners();
    return true;
  }

  Future<bool> cancelRideRequest(String requestId, String rideId) async {
    final result = await _repo.cancelRideRequest(requestId);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    _myRequestMap.remove(rideId);
    notifyListeners();
    return true;
  }

  // ── Owner Actions ─────────────────────────────────────────────────────────
  Future<bool> acceptRequest(String requestId, String rideId) async {
    final result = await _repo.acceptRideRequest(requestId);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    await loadRideDetail(rideId);
    await loadRideRequests(rideId);
    return true;
  }

  Future<bool> rejectRequest(String requestId, String rideId) async {
    final result = await _repo.rejectRideRequest(requestId);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    rideRequests = rideRequests
        .where((r) => r.id != requestId)
        .toList();
    notifyListeners();
    return true;
  }

  Future<bool> leaveRide(String rideId) async {
    final result = await _repo.leaveRide(rideId);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    joinedRides = joinedRides.where((r) => r.id != rideId).toList();
    notifyListeners();
    return true;
  }

  Future<bool> completeRide(String rideId) async {
    final result = await _repo.completeRide(rideId);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    _updateRideStatus(rideId, 'done');
    return true;
  }

  Future<bool> cancelRide(String rideId) async {
    final result = await _repo.cancelRide(rideId);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    _updateRideStatus(rideId, 'cancelled');
    return true;
  }

  Future<bool> deleteRide(String rideId) async {
    final result = await _repo.deleteRide(rideId);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    rides = rides.where((r) => r.id != rideId).toList();
    myRides = myRides.where((r) => r.id != rideId).toList();
    notifyListeners();
    return true;
  }

  void _updateRideStatus(String rideId, String status) {
    // ignore: prefer_function_declarations_over_variables
    RideModel update(RideModel r) => r.id == rideId
        ? RideModel.fromJson({
            '_id': r.id,
            'userId': r.userId,
            'userName': r.userName,
            'type': r.type,
            'from': r.from.toJson(),
            'to': r.to.toJson(),
            'departureTime': r.departureTime.toIso8601String(),
            'participants': r.participants
                .map((p) => {
                      'userId': p.userId,
                      'userName': p.userName,
                      'joinedAt': p.joinedAt.toIso8601String(),
                    })
                .toList(),
            'description': r.description,
            'contact': r.contact,
            'status': status,
            'createdAt': r.createdAt.toIso8601String(),
          })
        : r;

    rides = rides.map(update).toList();
    myRides = myRides.map(update).toList();
    if (currentRide?.id == rideId) {
      currentRide = update(currentRide!);
    }
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
