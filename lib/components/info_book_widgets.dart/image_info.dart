import 'dart:ui';

import 'package:flutter/material.dart';

class Image_Info extends StatelessWidget {
  String linkImage;
  Image_Info({super.key, required this.linkImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(linkImage),
                  // image: AssetImage('assets/images/banner.jpg'),
                  fit: BoxFit.cover),
            ),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                width: double.infinity,
                height: 270,
                color: Colors.white.withOpacity(0.4), // lớp phủ trắng mờ mờ
              ),
            ),
          ),
          Container(
            height: 250,
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                linkImage,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 5,
            child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 32,
                  color: Theme.of(context).colorScheme.secondary,
                )),
          ),
        ],
      ),
    );
  }
}
