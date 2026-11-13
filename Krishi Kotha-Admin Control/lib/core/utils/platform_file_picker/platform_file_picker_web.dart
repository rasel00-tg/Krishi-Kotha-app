import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'platform_file_picker_stub.dart';

export 'platform_file_picker_stub.dart';

/// Web implementation using native browser FileUploadInputElement
Future<PickedAdminFile?> pickLocalImageFile() async {
  final completer = Completer<PickedAdminFile?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.multiple = false;
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(PickedAdminFile(
            name: file.name,
            bytes: result,
            size: file.size,
          ));
        } else if (result is ByteBuffer) {
          completer.complete(PickedAdminFile(
            name: file.name,
            bytes: result.asUint8List(),
            size: file.size,
          ));
        } else if (result is List<int>) {
          completer.complete(PickedAdminFile(
            name: file.name,
            bytes: Uint8List.fromList(result),
            size: file.size,
          ));
        } else {
          completer.complete(null);
        }
      });
      reader.onError.listen((_) => completer.complete(null));
      reader.readAsArrayBuffer(file);
    } else {
      completer.complete(null);
    }
  });

  return completer.future;
}

