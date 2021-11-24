import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_overlayentry/dropdown_overlayentry.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<DropdownOverlayEntryState> _dropdownOverlayEntry = GlobalKey();

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
            DropdownOverlayEntry.closeAll();
            FocusScope.of(context).unfocus();
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
                    triggerBuilder: (context, key, isOpen, toggle) => MaterialButton(
                      key: key,
                      onPressed: () => _dropdownOverlayEntry.currentState!.toggle(),
                      child: Text(
                        'Button is ${isOpen ? 'open' : 'closed'}',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Colors.green,
                      minWidth: MediaQuery.of(context).size.width * 0.5,
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
                  OptimalInteractiveContent(),
                  AutoInteractiveContent(),
                  Container(
                    width: 500,
                    height: 600,
                    padding: const EdgeInsets.only(top: 16),
                    child: ScrollViewSample(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OptimalInteractiveContent extends StatefulWidget {
  const OptimalInteractiveContent({Key? key}) : super(key: key);

  @override
  State<OptimalInteractiveContent> createState() => _OptimalInteractiveContentState();
}

class _OptimalInteractiveContentState extends State<OptimalInteractiveContent> {
  GlobalKey<DropdownOverlayEntryState> _dropdownOverlayParentInteractive = GlobalKey();
  int nItems = 0;
  FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return DropdownOverlayEntry(
      key: _dropdownOverlayParentInteractive,
      triggerBuilder: (context, key, isOpen, toggle) => SizedBox(
        width: 500,
        child: TextFormField(
          focusNode: _focusNode,
          key: key,
          onChanged: _updateInteractiveContent,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
          decoration: InputDecoration(
            labelText: 'Optimal Interactive Content',
          ),
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
    );
  }

  void _updateInteractiveContent(String text) {
    nItems = int.tryParse(text) ?? nItems;
    _dropdownOverlayParentInteractive.currentState!.rebuild();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _dropdownOverlayParentInteractive.currentState!.open();
      } else {
        _dropdownOverlayParentInteractive.currentState!.close();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }
}

class AutoInteractiveContent extends StatefulWidget {
  const AutoInteractiveContent({Key? key}) : super(key: key);

  @override
  State<AutoInteractiveContent> createState() => _AutoInteractiveContentState();
}

class _AutoInteractiveContentState extends State<AutoInteractiveContent> {
  int nItems = 0;
  FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return DropdownOverlayEntry(
      isOpen: _focusNode.hasFocus,
      triggerBuilder: (context, key, isOpen, toggle) => SizedBox(
        width: 500,
        child: TextFormField(
          focusNode: _focusNode,
          key: key,
          onChanged: _updateInteractiveContent,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
          decoration: InputDecoration(
            labelText: 'Auto Interactive Content',
          ),
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
    );
  }

  void _updateInteractiveContent(String text) {
    setState(() {
      nItems = int.tryParse(text) ?? nItems;
    });
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }
}

class ScrollViewSample extends StatefulWidget {
  const ScrollViewSample({Key? key}) : super(key: key);

  @override
  State<ScrollViewSample> createState() => _ScrollViewSampleState();
}

class _ScrollViewSampleState extends State<ScrollViewSample> {
  ScrollController _scrollController = ScrollController();
  GlobalKey _container = GlobalKey();
  Rect? _containerRect;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _container,
      decoration: BoxDecoration(border: Border.all()),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'scroll demo',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 500),
              height: 2000,
              alignment: Alignment.topCenter,
              child: DropdownOverlayEntry(
                scrollController: _scrollController,
                alignment: (buttonRect) {
                  final fromTop = buttonRect.top - _containerRect!.top;
                  if (fromTop < 0) {
                    DropdownOverlayEntry.closeAll();
                  }
                  if (fromTop < _containerRect!.height / 2) {
                    return Offset(0, buttonRect.height);
                  } else {
                    return Offset(0, -300);
                  }
                },
                dropdownBuilder: (context, buttonRect) => IgnorePointer(
                  child: Container(
                    width: buttonRect.width,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
                triggerBuilder: (context, key, isOpen, toggle) => MaterialButton(
                  key: key,
                  onPressed: toggle,
                  child: Text(
                    'Button is ${isOpen ? 'open' : 'closed'}',
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.green,
                  minWidth: MediaQuery.of(context).size.width * 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _getContainerRect() {
    final ro = _container.currentContext!.findRenderObject()!;
    final box = (ro as RenderBox);
    final topLeft = box.localToGlobal(Offset.zero);
    final bottomRight = topLeft + box.size.bottomRight(Offset.zero);
    _containerRect = Rect.fromPoints(topLeft, bottomRight);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      _getContainerRect();
    });
  }
}
