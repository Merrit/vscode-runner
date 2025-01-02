import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

/// A very basic notifications implementation, added so we can inform the
/// user of any errors that occur.

/// Sends a notification with the given [title] and [body].
Future<void> sendNotification({
  required String title,
  required String body,
}) async {
  final client = XdgDesktopPortalClient();

  await client.notification.addNotification(
    title,
    title: 'VS Code Runner: $title',

    /// TODO: Once the notification package supports `markup-body`, use it here
    /// so that for example notifications can contain clickable links, the way
    /// that [MissingSQLite3Exception] is trying to do.
    /// See: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Notification.html#org-freedesktop-portal-notification-addnotification
    body: body,
    priority: XdgNotificationPriority.urgent,
  );

  await client.close();
}
