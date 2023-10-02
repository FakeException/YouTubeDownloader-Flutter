import 'package:flutter/material.dart';
import 'package:youtube_downloader/widgets/settings_screen.dart';

import '../main.dart';

class YouTubeDrawer extends StatelessWidget {
  const YouTubeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DrawerHead(),
            const SizedBox(
              height: 16.0,
            ),
            DrawerNavigationItem(
              iconData: Icons.download,
              title: "Download Videos",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) {
                  return const YoutubeDownloader();
                }));
              },
              selected: true,
            ),
            DrawerNavigationItem(
              iconData: Icons.settings,
              title: "Settings",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) {
                  return const Settings();
                }));
              },
              selected: true,
            ),
          ],
        )),
      ),
    );
  }

}

class DrawerNavigationItem extends StatelessWidget {
  final IconData iconData;
  final String title;
  final bool selected;
  final Function()? onTap;
  const DrawerNavigationItem({
    Key? key,
    required this.iconData,
    required this.title,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        leading: Icon(iconData),
        onTap: onTap,
        title: Text(title),
        selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        selected: selected,
      ),
    );
  }
}

class DrawerHead extends StatelessWidget {
  const DrawerHead({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "YouTube Downloader",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}