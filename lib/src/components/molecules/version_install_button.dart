import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sidekick/generated/l10n.dart';

import '../../dto/release.dto.dart';
import '../../modules/fvm/fvm_queue.provider.dart';

String installedMsg = S.current.versionIsInstalled;
String notInstalledMsg = S.current.versionNotInstalledClickToInstall;

class VersionInstallButton extends HookWidget {
  final ReleaseDto version;
  final bool warningIcon;
  const VersionInstallButton(this.version, {this.warningIcon = false, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isQueued = useState(false);
    final hovering = useState(false);
    final queueProvider = useProvider(fvmQueueProvider);

    useEffect(() {
      final isInstalling = queueProvider.activeItem != null &&
          queueProvider.activeItem.version == version;

      if (isInstalling) {
        isQueued.value = true;
        return;
      }

      final queued = queueProvider.queue.firstWhere(
        (item) => item.version == version,
        orElse: () => null,
      );

      isQueued.value = queued != null;
      return;
    }, [queueProvider]);

    Future<void> onInstall() async {
      isQueued.value = true;
      // Add it to queue for installation
      context.read(fvmQueueProvider.notifier).install(version);
    }

    Widget installIcon() {
      if ((isQueued.value && !version.isCached)) {
        return SizedBox(
          height: 20,
          width: 20,
          child: SpinKitFadingFour(
            size: 15,
            color: Theme.of(context).accentColor,
          ),
        );
      }

      if (version.isCached) {
        return Icon(
          Icons.check,
          size: 20,
          color: Theme.of(context).accentColor,
        );
      }

      // Display warning icon instead of download arrow
      if (warningIcon) {
        return const Icon(MdiIcons.alert, size: 20);
      }
      return const Icon(Icons.arrow_downward, size: 20);
    }

    return MouseRegion(
      onHover: (_) {
        if (!hovering.value) {
          hovering.value = true;
        }
      },
      onExit: (_) {
        if (hovering.value) {
          hovering.value = false;
        }
      },
      child: Opacity(
        opacity: version.isCached ? 0.3 : 1,
        child: IconButton(
          onPressed: version.isCached ? onInstall : onInstall,
          splashRadius: 20,
          icon: Tooltip(
              message: version.isCached ? installedMsg : notInstalledMsg,
              child: installIcon()),
        ),
      ),
    );
  }
}
