import 'dart:async';

import 'package:flutter/material.dart';
import '../models/swaprequest_model.dart';

import '../services/swap_service.dart';

class SwapRequestState extends ChangeNotifier {
  final SwapService _swapService;
  final String _userId;
  List<SwapRequestModel> _receivedRequests = [];
  StreamSubscription<List<SwapRequestModel>>? _requestsSubscription;

  SwapRequestState(this._swapService, this._userId) {
    if (_userId.isNotEmpty) {
      _listenToRequests();
    }
  }

  List<SwapRequestModel> get receivedRequests => _receivedRequests;

  void _listenToRequests() {
    _requestsSubscription?.cancel();
    _requestsSubscription = _swapService.watchReceivedRequests(_userId).listen(
      (requests) {
        _receivedRequests = requests;
        notifyListeners();
      },
      onError: (e) => print('SwapRequestState: Error watching requests - $e'),
    );
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User ID is not set');
      }
      if (requestId.isEmpty) {
        throw Exception('Request ID is empty');
      }

      print('SwapRequestState: Accepting request with ID: $requestId');
      await _swapService.acceptSwapRequest(requestId, _userId);
      print('SwapRequestState: Request $requestId accepted');
    } catch (e) {
      print('SwapRequestState: Error accepting request - $e');
      rethrow;
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      if (_userId.isEmpty) {
        throw Exception('User ID is not set');
      }
      if (requestId.isEmpty) {
        throw Exception('Request ID is empty');
      }

      print('SwapRequestState: Declining request with ID: $requestId');
      await _swapService.declineSwapRequest(requestId, _userId);
      print('SwapRequestState: Request $requestId declined');
    } catch (e) {
      print('SwapRequestState: Error declining request - $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }
}