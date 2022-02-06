// ignore_for_file: always_put_control_body_on_new_line, unnecessary_null_comparison

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../extended_text_library.dart';

///
///  create by zmtzawqlp on 2019/7/31
///

const double kExtendedMinInteractiveSize = 48.0;

/// The text position that a give selection handle manipulates. Dragging the
/// [start] handle always moves the [start]/[baseOffset] of the selection.
enum _TextSelectionHandlePosition { start, end }

/// An object that manages a pair of text selection handles.
///
/// The selection handles are displayed in the [Overlay] that most closely
/// encloses the given [BuildContext].
class ExtendedTextSelectionOverlay {
  /// Creates an object that manages overly entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  ExtendedTextSelectionOverlay({
    required TextEditingValue value,
    required this.context,
    this.debugRequiredFor,
    required this.toolbarLayerLink,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.renderObject,
    this.selectionControls,
    bool handlesVisible = false,
    this.selectionDelegate,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onSelectionHandleTapped,
    this.clipboardStatus,
  })  : assert(value != null),
        assert(context != null),
        assert(handlesVisible != null),
        _handlesVisible = handlesVisible,
        _value = value {
    final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    assert(
        overlay != null,
        'No Overlay widget exists above $context.\n'
        'Usually the Navigator created by WidgetsApp provides the overlay. Perhaps your '
        'app content was created above the Navigator with the WidgetsApp builder parameter.');
    _toolbarController =
        AnimationController(duration: fadeDuration, vsync: overlay!);
  }

  /// The context in which the selection handles should appear.
  ///
  /// This context must have an [Overlay] as an ancestor because this object
  /// will display the text selection handles in that [Overlay].
  final BuildContext context;

  /// Debugging information for explaining why the [Overlay] is required.
  final Widget? debugRequiredFor;

  /// The object supplied to the [CompositedTransformTarget] that wraps the text
  /// field.
  final LayerLink toolbarLayerLink;

  /// The objects supplied to the [CompositedTransformTarget] that wraps the
  /// location of start selection handle.
  final LayerLink startHandleLayerLink;

  /// The objects supplied to the [CompositedTransformTarget] that wraps the
  /// location of end selection handle.
  final LayerLink endHandleLayerLink;
  // (mpcomplete): what if the renderObject is removed or replaced, or
  // moves? Not sure what cases I need to handle, or how to handle them.
  /// The editable line in which the selected text is being displayed.
  final ExtendedTextSelectionRenderObject renderObject;

  /// Builds text selection handles and toolbar.
  final TextSelectionControls? selectionControls;

  /// The delegate for manipulating the current selection in the owning
  /// text field.
  final TextSelectionDelegate? selectionDelegate;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], handle drag behavior will
  /// begin at the position where the drag gesture won the arena. If set to
  /// [DragStartBehavior.down] it will begin at the position where a down
  /// event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  /// {@template flutter.widgets.TextSelectionOverlay.onSelectionHandleTapped}
  /// A callback that's optionally invoked when a selection handle is tapped.
  ///
  /// The [TextSelectionControls.buildHandle] implementation the text field
  /// uses decides where the handle's tap "hotspot" is, or whether the
  /// selection handle supports tap gestures at all. For instance,
  /// [MaterialTextSelectionControls] calls [onSelectionHandleTapped] when the
  /// selection handle's "knob" is tapped, while
  /// [CupertinoTextSelectionControls] builds a handle that's not sufficiently
  /// large for tapping (as it's not meant to be tapped) so it does not call
  /// [onSelectionHandleTapped] even when tapped.
  /// {@endtemplate}
  // See https://github.com/flutter/flutter/issues/39376#issuecomment-848406415
  // for provenance.
  final VoidCallback? onSelectionHandleTapped;

  /// Maintains the status of the clipboard for determining if its contents can
  /// be pasted or not.
  ///
  /// Useful because the actual value of the clipboard can only be checked
  /// asynchronously (see [Clipboard.getData]).
  final ClipboardStatusNotifier? clipboardStatus;

  /// Controls the fade-in and fade-out animations for the toolbar and handles.
  static const Duration fadeDuration = Duration(milliseconds: 150);

  late final AnimationController _toolbarController;
  Animation<double> get _toolbarOpacity => _toolbarController.view;

  /// Retrieve current value.
  @visibleForTesting
  TextEditingValue get value => _value;

  TextEditingValue _value;

  /// A pair of handles. If this is non-null, there are always 2, though the
  /// second is hidden when the selection is collapsed.
  List<OverlayEntry>? _handles;

  /// A copy/paste toolbar.
  OverlayEntry? _toolbar;

  TextSelection get _selection => _value.selection;

  /// Whether selection handles are visible.
  ///
  /// Set to false if you want to hide the handles. Use this property to show or
  /// hide the handle without rebuilding them.
  ///
  /// If this method is called while the [SchedulerBinding.schedulerPhase] is
  /// [SchedulerPhase.persistentCallbacks], i.e. during the build, layout, or
  /// paint phases (see [WidgetsBinding.drawFrame]), then the update is delayed
  /// until the post-frame callbacks phase. Otherwise the update is done
  /// synchronously. This means that it is safe to call during builds, but also
  /// that if you do call this during a build, the UI will not update until the
  /// next frame (i.e. many milliseconds later).
  ///
  /// Defaults to false.
  bool get handlesVisible => _handlesVisible;
  bool _handlesVisible = false;
  set handlesVisible(bool visible) {
    assert(visible != null);
    if (_handlesVisible == visible) return;
    _handlesVisible = visible;
    // If we are in build state, it will be too late to update visibility.
    // We will need to schedule the build in next frame.
    if (SchedulerBinding.instance!.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance!.addPostFrameCallback(_markNeedsBuild);
    } else {
      _markNeedsBuild();
    }
  }

  /// Builds the handles by inserting them into the [context]'s overlay.
  void showHandles() {
    if (_handles != null) return;

    _handles = <OverlayEntry>[
      OverlayEntry(
          builder: (BuildContext context) =>
              _buildHandle(context, _TextSelectionHandlePosition.start)),
      OverlayEntry(
          builder: (BuildContext context) =>
              _buildHandle(context, _TextSelectionHandlePosition.end)),
    ];
    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor)!
        .insertAll(_handles!);
  }

  /// Destroys the handles by removing them from overlay.
  void hideHandles() {
    if (_handles != null) {
      _handles![0].remove();
      _handles![1].remove();
      _handles = null;
    }
  }

  /// Shows the toolbar by inserting it into the [context]'s overlay.
  void showToolbar() {
    assert(_toolbar == null);
    _toolbar = OverlayEntry(builder: _buildToolbar);
    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor)!
        .insert(_toolbar!);
    _toolbarController.forward(from: 0.0);
  }

  /// Updates the overlay after the selection has changed.
  ///
  /// If this method is called while the [SchedulerBinding.schedulerPhase] is
  /// [SchedulerPhase.persistentCallbacks], i.e. during the build, layout, or
  /// paint phases (see [WidgetsBinding.drawFrame]), then the update is delayed
  /// until the post-frame callbacks phase. Otherwise the update is done
  /// synchronously. This means that it is safe to call during builds, but also
  /// that if you do call this during a build, the UI will not update until the
  /// next frame (i.e. many milliseconds later).
  void update(TextEditingValue newValue) {
    if (_value == newValue) return;
    _value = newValue;
    if (SchedulerBinding.instance!.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance!.addPostFrameCallback(_markNeedsBuild);
    } else {
      _markNeedsBuild();
    }
  }

  /// Causes the overlay to update its rendering.
  ///
  /// This is intended to be called when the [renderObject] may have changed its
  /// text metrics (e.g. because the text was scrolled).
  void updateForScroll() {
    _markNeedsBuild();
  }

  void _markNeedsBuild([Duration? duration]) {
    if (_handles != null) {
      _handles![0].markNeedsBuild();
      _handles![1].markNeedsBuild();
    }
    _toolbar?.markNeedsBuild();
  }

  /// Whether the handles are currently visible.
  bool get handlesAreVisible => _handles != null && handlesVisible;

  /// Whether the toolbar is currently visible.
  bool get toolbarIsVisible => _toolbar != null;

  /// Hides the entire overlay including the toolbar and the handles.
  void hide() {
    if (_handles != null) {
      _handles![0].remove();
      _handles![1].remove();
      _handles = null;
    }
    if (_toolbar != null) {
      hideToolbar();
    }
  }

  /// Hides the toolbar part of the overlay.
  ///
  /// To hide the whole overlay, see [hide].
  void hideToolbar() {
    assert(_toolbar != null);
    _toolbarController.stop();
    _toolbar?.remove();
    _toolbar = null;
  }

  /// Final cleanup.
  void dispose() {
    hide();
    _toolbarController.dispose();
  }

  Widget _buildHandle(
      BuildContext context, _TextSelectionHandlePosition position) {
    final Widget handle;
    final TextSelectionControls? selectionControls = this.selectionControls;
    if ((_selection.isCollapsed &&
            position == _TextSelectionHandlePosition.end) ||
        selectionControls == null)
      handle = Container(); // hide the second handle when collapsed
    else {
      handle = Visibility(
        visible: handlesVisible,
        child: _TextSelectionHandleOverlay(
          onSelectionHandleChanged: (TextSelection newSelection) {
            _handleSelectionHandleChanged(newSelection, position);
          },
          onSelectionHandleTapped: onSelectionHandleTapped,
          startHandleLayerLink: startHandleLayerLink,
          endHandleLayerLink: endHandleLayerLink,
          renderObject: renderObject,
          selection: _selection,
          selectionControls: selectionControls,
          position: position,
          dragStartBehavior: dragStartBehavior,
          selectionDelegate: selectionDelegate!,
        ),
      );
    }
    return ExcludeSemantics(
      child: handle,
    );
  }

  Widget _buildToolbar(BuildContext context) {
    if (selectionControls == null) return Container();

    // Find the horizontal midpoint, just above the selected text.
    final List<TextSelectionPoint>? endpoints =
        renderObject.getEndpointsForSelection(_selection);
    if (endpoints == null || endpoints.isEmpty) {
      return Container();
    }

    final Rect editingRegion = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );

    final bool isMultiline =
        endpoints.last.point.dy - endpoints.first.point.dy >
            renderObject.preferredLineHeight / 2;

    // If the selected text spans more than 1 line, horizontally center the toolbar.
    // Derived from both iOS and Android.
    final double midX = isMultiline
        ? editingRegion.width / 2
        : (endpoints.first.point.dx + endpoints.last.point.dx) / 2;

    final Offset midpoint = Offset(
      midX,
      // The y-coordinate won't be made use of most likely.
      endpoints[0].point.dy - renderObject.preferredLineHeight,
    );

    return Directionality(
      textDirection: Directionality.of(this.context),
      child: FadeTransition(
        opacity: _toolbarOpacity,
        child: CompositedTransformFollower(
          link: toolbarLayerLink,
          showWhenUnlinked: false,
          offset: -editingRegion.topLeft,
          child: Builder(
            builder: (BuildContext context) {
              return selectionControls!.buildToolbar(
                context,
                editingRegion,
                renderObject.preferredLineHeight,
                midpoint,
                endpoints,
                selectionDelegate!,
                clipboardStatus!,
                renderObject.lastSecondaryTapDownPosition,
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleSelectionHandleChanged(
      TextSelection newSelection, _TextSelectionHandlePosition position) {
    final TextPosition textPosition;
    switch (position) {
      case _TextSelectionHandlePosition.start:
        textPosition = newSelection.base;
        break;
      case _TextSelectionHandlePosition.end:
        textPosition = newSelection.extent;
        break;
    }
    selectionDelegate!.userUpdateTextEditingValue(
      _value.copyWith(selection: newSelection),
      SelectionChangedCause.drag,
    );
    selectionDelegate!.bringIntoView(textPosition);
  }
}

/// This widget represents a single draggable text selection handle.
class _TextSelectionHandleOverlay extends StatefulWidget {
  const _TextSelectionHandleOverlay({
    Key? key,
    required this.selection,
    required this.position,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.renderObject,
    required this.onSelectionHandleChanged,
    required this.onSelectionHandleTapped,
    required this.selectionControls,
    required this.selectionDelegate,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final ExtendedTextSelectionRenderObject renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final VoidCallback? onSelectionHandleTapped;
  final TextSelectionControls selectionControls;
  final DragStartBehavior dragStartBehavior;
  final TextSelectionDelegate selectionDelegate;

  @override
  _TextSelectionHandleOverlayState createState() =>
      _TextSelectionHandleOverlayState();

  ValueListenable<bool> get _visibility {
    switch (position) {
      case _TextSelectionHandlePosition.start:
        return renderObject.selectionStartInViewport;
      case _TextSelectionHandlePosition.end:
        return renderObject.selectionEndInViewport;
    }
  }
}

class _TextSelectionHandleOverlayState
    extends State<_TextSelectionHandleOverlay>
    with SingleTickerProviderStateMixin {
  late Offset _dragPosition;

  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: TextSelectionOverlay.fadeDuration, vsync: this);

    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget._visibility.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(_TextSelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget._visibility.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget._visibility.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    final Size handleSize = widget.selectionControls.getHandleSize(
      widget.renderObject.preferredLineHeight,
    );
    _dragPosition = details.globalPosition + Offset(0.0, -handleSize.height);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    TextPosition position =
        widget.renderObject.getPositionForPoint(_dragPosition);

    ///zmt
    if (widget.renderObject.hasSpecialInlineSpanBase) {
      position = convertTextPainterPostionToTextInputPostion(
          widget.renderObject.text!, position)!;
    }

    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(TextSelection.fromPosition(position));
      return;
    }

    final TextSelection newSelection;
    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: widget.selection.extentOffset,
        );
        break;
      case _TextSelectionHandlePosition.end:
        newSelection = TextSelection(
          baseOffset: widget.selection.baseOffset,
          extentOffset: position.offset,
        );
        break;
    }

    if (newSelection.baseOffset >= newSelection.extentOffset)
      return; // don't allow order swapping.

    widget.onSelectionHandleChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    final LayerLink layerLink;
    final TextSelectionHandleType type;

    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        layerLink = widget.startHandleLayerLink;
        type = _chooseType(
          widget.renderObject.textDirection,
          TextSelectionHandleType.left,
          TextSelectionHandleType.right,
        );
        break;
      case _TextSelectionHandlePosition.end:
        // For collapsed selections, we shouldn't be building the [end] handle.
        assert(!widget.selection.isCollapsed);
        layerLink = widget.endHandleLayerLink;
        type = _chooseType(
          widget.renderObject.textDirection,
          TextSelectionHandleType.right,
          TextSelectionHandleType.left,
        );
        break;
    }

    // On some platforms we may want to calculate the start and end handles
    // separately so they scale for the selected content.
    //
    // For the start handle we compute the rectangles that encompass the range
    // of the first full selected grapheme cluster at the beginning of the selection.
    //
    // For the end handle we compute the rectangles that encompass the range
    // of the last full selected grapheme cluster at the end of the selection.
    //
    // Only calculate start/end handle rects if the text in the previous frame
    // is the same as the text in the current frame. This is done because
    // widget.renderObject contains the renderEditable from the previous frame.
    // If the text changed between the current and previous frames then
    // widget.renderObject.getRectForComposingRange might fail. In cases where
    // the current frame is different from the previous we fall back to
    // widget.renderObject.preferredLineHeight.
    final InlineSpan span = widget.renderObject.text!;
    final String prevText = span.toPlainText();
    final String currText = widget.selectionDelegate.textEditingValue.text;
    final int firstSelectedGraphemeExtent;
    final int lastSelectedGraphemeExtent;
    final TextSelection selection = widget.selection;
    Rect? startHandleRect;
    Rect? endHandleRect;

    if (prevText == currText &&
        selection != null &&
        selection.isValid &&
        !selection.isCollapsed) {
      final String selectedGraphemes = selection.textInside(currText);
      firstSelectedGraphemeExtent = selectedGraphemes.characters.first.length;
      lastSelectedGraphemeExtent = selectedGraphemes.characters.last.length;
      assert(firstSelectedGraphemeExtent <= selectedGraphemes.length &&
          lastSelectedGraphemeExtent <= selectedGraphemes.length);
      startHandleRect = widget.renderObject.getRectForComposingRange(TextRange(
          start: selection.start,
          end: selection.start + firstSelectedGraphemeExtent));
      endHandleRect = widget.renderObject.getRectForComposingRange(TextRange(
          start: selection.end - lastSelectedGraphemeExtent,
          end: selection.end));
    }

    final Offset handleAnchor = widget.selectionControls.getHandleAnchor(
      type,
      widget.renderObject.preferredLineHeight,
      startHandleRect?.height ?? widget.renderObject.preferredLineHeight,
      endHandleRect?.height ?? widget.renderObject.preferredLineHeight,
    );
    final Size handleSize = widget.selectionControls.getHandleSize(
      widget.renderObject.preferredLineHeight,
    );

    final Rect handleRect = Rect.fromLTWH(
      -handleAnchor.dx,
      -handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    // Make sure the GestureDetector is big enough to be easily interactive.
    final Rect interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(
          center: handleRect.center, radius: kMinInteractiveDimension / 2),
    );
    final RelativeRect padding = RelativeRect.fromLTRB(
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: layerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          alignment: Alignment.topLeft,
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: widget.dragStartBehavior,
            onPanStart: _handleDragStart,
            onPanUpdate: _handleDragUpdate,
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
              ),
              child: widget.selectionControls.buildHandle(
                context,
                type,
                widget.renderObject.preferredLineHeight,
                widget.onSelectionHandleTapped,
                startHandleRect?.height ??
                    widget.renderObject.preferredLineHeight,
                endHandleRect?.height ??
                    widget.renderObject.preferredLineHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextSelectionHandleType _chooseType(
    TextDirection textDirection,
    TextSelectionHandleType ltrType,
    TextSelectionHandleType rtlType,
  ) {
    if (widget.selection.isCollapsed) return TextSelectionHandleType.collapsed;

    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
  }
}
