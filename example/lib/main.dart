import 'package:flutter/material.dart';
import 'package:dropdown_overlayentry/dropdown_overlayentry.dart';
import 'package:gm5_utils/extended_functionality/context.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<DropdownOverlayEntryState> _dropdownOverlayEntry = GlobalKey();
  GlobalKey<DropdownOverlayEntryState> _dropdownOverlayParentInteractive = GlobalKey();
  int nItems = 0;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _dropdownOverlayParentInteractive.currentState.open();
      } else {
        _dropdownOverlayParentInteractive.currentState.close();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dropdown OverlayEntry example'),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            print('unfocus');
            _focusNode.unfocus();
          },
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DropdownOverlayEntry(
                    key: _dropdownOverlayEntry,
                    triggerBuilder: (context, key, isOpen) => MaterialButton(
                      key: key,
                      onPressed: () => _dropdownOverlayEntry.currentState.toggle(),
                      child: Text(
                        'Button is ${isOpen ? 'open' : 'closed'}',
                      ),
                      color: Colors.blue,
                      minWidth: context.width * 0.5,
                    ),
                    dropdownBuilder: (context, buttonRect) {
                      return Container(
                        width: buttonRect.width,
                        height: 500,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10),
                          ],
                        ),
                      );
                    },
                  ),
                  DropdownOverlayEntry(
                    key: _dropdownOverlayParentInteractive,
                    triggerBuilder: (context, key, isOpen) => SizedBox(
                      width: 500,
                      child: TextFormField(
                        focusNode: _focusNode,
                        key: key,
                        onChanged: _updateInteractiveContent,
                      ),
                    ),
                    alignmentOffset: Offset(0, 4),
                    dropdownBuilder: (context, buttonRect) {
                      return Container(
                        width: buttonRect.width,
                        height: 500,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10),
                          ],
                        ),
                        child: ListView.builder(
                          itemCount: nItems,
                          itemBuilder: (ctx, i) => ListTile(
                            title: Text('Item $i'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateInteractiveContent(String text) {
    nItems = int.tryParse(text) ?? nItems;
    _dropdownOverlayParentInteractive.currentState.rebuild();
  }
}
