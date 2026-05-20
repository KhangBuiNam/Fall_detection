import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Simple MJPEG stream viewer
class MjpegView extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;

  const MjpegView({
    super.key,
    required this.streamUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  Uint8List? _currentFrame;
  StreamSubscription<List<int>>? _subscription;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void didUpdateWidget(covariant MjpegView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.streamUrl != widget.streamUrl) {
      _stopStream();
      _startStream();
    }
  }

  Future<void> _startStream() async {
    try {
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final response = await request.send();

      List<int> buffer = [];

      _subscription = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);

          while (true) {
            final start = _findJpegStart(buffer);
            final end = _findJpegEnd(buffer);

            if (start != -1 && end != -1 && end > start) {
              final jpg = Uint8List.fromList(
                buffer.sublist(start, end + 2),
              );

              setState(() {
                _currentFrame = jpg;
                _loading = false;
                _error = false;
              });

              buffer = buffer.sublist(end + 2);
            } else {
              break;
            }
          }
        },
        onError: (e) {
          setState(() {
            _error = true;
            _loading = false;
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  int _findJpegStart(List<int> data) {
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 0xFF && data[i + 1] == 0xD8) {
        return i;
      }
    }
    return -1;
  }

  int _findJpegEnd(List<int> data) {
    for (int i = 0; i < data.length - 1; i++) {
      if (data[i] == 0xFF && data[i + 1] == 0xD9) {
        return i;
      }
    }
    return -1;
  }

  void _stopStream() {
    _subscription?.cancel();
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              SizedBox(height: 10),
              Text(
                'Cannot connect to stream',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading || _currentFrame == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Image.memory(
      _currentFrame!,
      gaplessPlayback: true,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
