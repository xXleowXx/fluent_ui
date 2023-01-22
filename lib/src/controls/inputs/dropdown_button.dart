import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

const double _kVerticalOffset = 8.0;
const Widget _kDefaultDropdownButtonTrailing = Icon(
  FluentIcons.chevron_down,
  size: 10,
);

typedef DropDownButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback? onOpen,
);

/// A `DropDownButton` is a button that shows a chevron as a visual indicator that
/// it has an attached flyout that contains more options. It has the same
/// behavior as a standard Button control with a flyout; only the appearance is
/// different.
///
/// ![DropDownButton Showcase](https://docs.microsoft.com/en-us/windows/apps/design/controls/images/drop-down-button-align.png)
///
/// See also:
///
///   * [Flyout], a light dismiss container that can show arbitrary UI as its
///  content. Used to back this button
///   * [ComboBox], a list of items that a user can select from
///   * <https://docs.microsoft.com/en-us/windows/apps/design/controls/buttons#create-a-drop-down-button>
class DropDownButton extends StatefulWidget {
  /// Creates a dropdown button.
  const DropDownButton({
    Key? key,
    this.buttonBuilder,
    required this.items,
    this.leading,
    this.title,
    this.trailing,
    this.verticalOffset = _kVerticalOffset,
    this.closeAfterClick = true,
    this.disabled = false,
    this.focusNode,
    this.autofocus = false,
    this.buttonStyle,
    this.placement = FlyoutPlacementMode.bottomCenter,
    this.menuShape,
    this.menuColor,
    this.onOpen,
    this.onClose,
  })  : assert(items.length > 0, 'You must provide at least one item'),
        super(key: key);

  /// A builder for the button. If null, a [Button] with [leading], [title] and
  /// [trailing] is used.
  ///
  /// If [disabled] is true, [DropDownButtonBuilder.onOpen] will be null
  final DropDownButtonBuilder? buttonBuilder;

  /// The content at the start of this widget.
  ///
  /// Usually an [Icon]
  final Widget? leading;

  /// Title show a content at the center of this widget.
  ///
  /// Usually a [Text]
  final Widget? title;

  /// Trailing show a content at the right of this widget.
  ///
  /// If null, a chevron_down is displayed.
  final Widget? trailing;

  /// The space between the button and the flyout.
  ///
  /// 8.0 is used by default
  final double verticalOffset;

  /// The items in the flyout. Must not be empty
  final List<MenuFlyoutItem> items;

  /// Whether the flyout will be closed after an item is tapped.
  ///
  /// Defaults to `true`
  final bool closeAfterClick;

  /// If `true`, the button won't be clickable.
  final bool disabled;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Customizes the button's appearance.
  @Deprecated('buttonStyle was deprecated in 3.11.1. Use buttonBuilder instead')
  final ButtonStyle? buttonStyle;

  /// The placement of the flyout.
  ///
  /// [FlyoutPlacement.center] is used by default
  final FlyoutPlacementMode placement;

  /// The menu shape
  final ShapeBorder? menuShape;

  /// The menu color. If null, [ThemeData.menuColor] is used
  final Color? menuColor;

  /// Called when the flyout is opened
  ///
  /// See also:
  ///
  ///  * [Flyout.onClose]
  final VoidCallback? onOpen;

  /// Called when the flyout is closed
  ///
  /// See also:
  ///
  ///  * [Flyout.onClose]
  final VoidCallback? onClose;

  @override
  State<DropDownButton> createState() => _DropDownButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MenuFlyoutItemInterface>('items', items))
      ..add(DoubleProperty(
        'verticalOffset',
        verticalOffset,
        defaultValue: _kVerticalOffset,
      ))
      ..add(FlagProperty(
        'close after click',
        value: closeAfterClick,
        defaultValue: false,
        ifFalse: 'do not close after click',
      ))
      ..add(EnumProperty<FlyoutPlacementMode>('placement', placement))
      ..add(DiagnosticsProperty<ShapeBorder>('menu shape', menuShape))
      ..add(ColorProperty('menu color', menuColor));
  }
}

class _DropDownButtonState extends State<DropDownButton> {
  final flyoutController = FlyoutController();

  @override
  void dispose() {
    flyoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    assert(debugCheckHasDirectionality(context));

    // See: https://github.com/flutter/flutter/issues/16957#issuecomment-558878770
    List<Widget> space(Iterable<Widget> children) => children
        .expand((item) sync* {
          yield const SizedBox(width: 8.0);
          yield item;
        })
        .skip(1)
        .toList();

    final buttonChildren = space(<Widget>[
      if (widget.leading != null)
        IconTheme.merge(
          data: const IconThemeData(size: 20.0),
          child: widget.leading!,
        ),
      if (widget.title != null) widget.title!,
      widget.trailing ?? _kDefaultDropdownButtonTrailing,
    ]);

    return FlyoutAttach(
      controller: flyoutController,
      child: Builder(builder: (context) {
        return widget.buttonBuilder?.call(
              context,
              widget.disabled ? null : showFlyout,
            ) ??
            Button(
              onPressed: widget.disabled ? null : showFlyout,
              autofocus: widget.autofocus,
              focusNode: widget.focusNode,
              // ignore: deprecated_member_use_from_same_package
              style: widget.buttonStyle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: buttonChildren,
              ),
            );
      }),
    );
  }

  void showFlyout() async {
    widget.onOpen?.call();
    await flyoutController.showFlyout(
      placementMode: widget.placement,
      additionalOffset: widget.verticalOffset,
      builder: (context) {
        return MenuFlyout(
          color: widget.menuColor,
          shape: widget.menuShape,
          items: widget.items.map((item) {
            if (widget.closeAfterClick) {
              return MenuFlyoutItem(
                onPressed: () {
                  Navigator.of(context).pop();
                  item.onPressed?.call();
                },
                key: item.key,
                leading: item.leading,
                text: item.text,
                trailing: item.trailing,
                selected: item.selected,
              );
            }
            return item;
          }).toList(),
        );
      },
    );
    widget.onClose?.call();
  }
}

/// An item used by [DropDownButton].
@Deprecated('DropDownButtonItem is deprecated. Use MenuFlyoutItem instead')
class DropDownButtonItem extends MenuFlyoutItem {
  /// Creates a drop down button item
  DropDownButtonItem({
    Key? key,
    required VoidCallback? onTap,
    Widget? leading,
    Widget? title,
    Widget? trailing,
  })  : assert(
          leading != null || title != null || trailing != null,
          'You must provide at least one property: leading, title or trailing',
        ),
        super(
          key: key,
          leading: leading,
          text: title ?? const SizedBox.shrink(),
          trailing: trailing,
          onPressed: onTap,
        );
}
