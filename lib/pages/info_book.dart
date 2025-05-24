import 'package:btl/components/info_book_widgets.dart/slivertoboxadapter_widget.dart';
import 'package:btl/components/info_book_widgets.dart/tab_view_info.dart';
import 'package:flutter/material.dart';

class Info extends StatefulWidget {
  Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
  }

  void _scrollDown() {
    _tabController.animateTo(
      0,
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 400),
    );

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as String?;
    if (args == null) {
      return Scaffold(body: Center(child: Text('Invalid book data')));
    }
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: NestedScrollView(
            controller: _scrollController,
            physics: ClampingScrollPhysics(),
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) => [
              // Tên truyện - Tóm tắt - Đánh giá - Bình luân.
              SlivertoboxadapterWidget(
                scrollDown: _scrollDown,
                linkImage: args,
              ),

              // Tabbar
              SliverPersistentHeader(
                pinned: true,
                floating: false,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        text: ('Chương'),
                      ),
                      Tab(
                        text: ('Liên quan'),
                      ),
                    ],
                    tabAlignment: TabAlignment.start,
                    splashBorderRadius: BorderRadius.circular(20),
                    labelColor: Colors.black,
                    indicator: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    // dividerColor: Colors.amber,
                    dividerColor: Colors.transparent,
                    isScrollable: true,
                  ),
                ),
              ),
            ],

            // TabView cho mỗi tabbar
            body: TabBarViewInfo(
              tabController: _tabController,
              linkImage: args ?? "",
            ),
          ),
        ),
      ),
    );
  }
}

// Delegate để tạo SliverPersistentHeader chứa TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black, width: 0.4))),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar;
  }
}
