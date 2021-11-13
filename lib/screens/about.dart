import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../utils/extension_helper.dart';

final version = '0.0.1';

class About extends StatelessWidget {
  const About({Key? key}) : super(key: key);

  Widget _listItem(
          BuildContext context, String text, IconData icons, String url) =>
      InkWell(
        onTap: () => url.launchUrl,
        child: Container(
          height: 50.0,
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(
              bottom: Divider.createBorderSide(context),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icons, color: context.accentColor),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
              ),
              Text(text),
            ],
          ),
        ),
      );

  Widget _translatorInfo(BuildContext context, {required String name, String? flag}) =>
      Container(
        height: 50.0,
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border(
            bottom: Divider.createBorderSide(context),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(LineIcons.user, color: context.accentColor),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
            ),
            Expanded(
                child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.fade,
            )),
            if (flag != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image(
                  image: AssetImage('assets/$flag.png'),
                  height: 20,
                  width: 30,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s!;
    return Container(
      height: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 110.0,
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image(
                    image: AssetImage('assets/logo.png'),
                    height: 80,
                  ),
                  Text(s.version(version)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Tsacdop is a podcast player built with flutter, a clean, simply beautiful and friendly app.',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () =>
                        'https://tsacdop.stonegate.me/#/privacy'.launchUrl,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.all(8),
                        primary: context.accentColor,
                        textStyle: TextStyle(fontWeight: FontWeight.bold)),
                    child: Text(
                      s.privacyPolicy,
                    ),
                  ),
                  SizedBox(width: 50),
                  TextButton(
                    onPressed: () =>
                        'https://tsacdop.stonegate.me/#/changelog'.launchUrl,
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.all(8),
                        primary: context.accentColor,
                        textStyle: TextStyle(fontWeight: FontWeight.bold)),
                    child: Text(s.changelog,
                        style: TextStyle(color: context.accentColor)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
            ),
            SizedBox(
              height: 400,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: [
                              SizedBox(width: 25),
                              Text(
                                s.developer,
                                style: TextStyle(
                                    color: context.accentColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          _listItem(context, 'Twitter @tsacdop',
                              LineIcons.twitter, 'https://twitter.com/tsacdop'),
                          _listItem(context, 'GitHub', LineIcons.alternateGithub,
                              'https://github.com/tsacdop/tsacdop_desktop'),
                          _listItem(context, 'Telegram', LineIcons.telegram,
                              'https://t.me/joinchat/Bk3LkRpTHy40QYC78PK7Qg'),
                          SizedBox(height: 30),
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: () =>
                                  'https://www.buymeacoffee.com/stonegate'
                                      .launchUrl,
                              style: ElevatedButton.styleFrom(
                                onSurface: Colors.transparent,
                                splashFactory: NoSplash.splashFactory,
                                shadowColor: Colors.transparent,
                                primary: context.accentColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                padding: EdgeInsets.zero,
                                minimumSize: Size(100, 58),
                              ),
                              child: Container(
                                height: 50.0,
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text('Buy Me A Coffee',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 10),
                                    Image(
                                      image:
                                          AssetImage('assets/buymeacoffee.png'),
                                      height: 30,
                                      fit: BoxFit.fitHeight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 100),
                  Expanded(
                    flex: 1,
                    child: LayoutBuilder(
                      builder: (context, constraint) => SizedBox(
                        width: math.min(constraint.maxHeight, 300),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: [
                                SizedBox(width: 25),
                                Text(
                                  s.translators,
                                  style: TextStyle(
                                      color: context.accentColor,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.favorite,
                                    color: Colors.red, size: 20),
                              ],
                            ),
                            _translatorInfo(context, name: 'Atrate'),
                            _translatorInfo(context, name: 'ppp', flag: 'fr'),
                            _translatorInfo(context,
                                name: 'Joel Israel', flag: 'mx'),
                            _translatorInfo(context,
                                name: 'Bruno Pinheiro', flag: 'pt'),
                            _translatorInfo(context,
                                name: 'Edoardo Maria Elidoro', flag: 'it'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
