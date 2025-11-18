// ignore_for_file: file_names
import 'package:arxiv/apis/arxiv.dart';
import 'package:arxiv/components/each_paper_card.dart';
import 'package:arxiv/components/loading_indicator.dart';
import 'package:arxiv/components/search_box.dart';
import 'package:arxiv/models/paper.dart';
import 'package:arxiv/pages/ai_chat_page.dart';
import 'package:arxiv/pages/bookmarks_page.dart';
import 'package:arxiv/pages/gwu_store.dart';
import 'package:arxiv/pages/how_to_use.dart';
import 'package:arxiv/pages/pdf_viewer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ionicons/ionicons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ------------------------------
  // BOTTOM NAV STATE
  // ------------------------------
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // ------------------------------
  // ORIGINAL VARIABLES
  // ------------------------------
  var sourceCodeURL = "https://github.com/dagmawibabi/ScholArxiv";
  int startPagination = 0;
  int maxContent = 30;
  int paginationGap = 30;
  var pdfBaseURL = "https://arxiv.org/pdf";
  bool sortOrderNewest = true;

  var isHomeScreenLoading = true;
  TextEditingController searchTermController = TextEditingController();

  var dio = Dio();
  List<Paper> data = [];

  // ------------------------------
  // FETCH & SEARCH LOGIC
  // ------------------------------
  Future<void> search({bool? resetPagination}) async {
    if (resetPagination == true) {
      startPagination = 0;
    }
    isHomeScreenLoading = true;
    data = [];
    setState(() {});

    var searchTerm = searchTermController.text.toString().trim();

    if (searchTerm.isNotEmpty) {
      data = await Arxiv.search(
        searchTerm,
        page: startPagination,
        pageSize: maxContent,
      );
    } else {
      data = await suggestedPapers();
    }

    await sortPapersByDate();
    isHomeScreenLoading = false;
    setState(() {});
  }

  Future<void> toggleSortOrder() async {
    setState(() {
      sortOrderNewest = !sortOrderNewest;
    });
    await sortPapersByDate();
  }

  Future<void> sortPapersByDate() async {
    if (data.isNotEmpty) {
      data.sort((a, b) {
        DateTime dateA = DateTime.parse(a.publishedAt);
        DateTime dateB = DateTime.parse(b.publishedAt);
        return sortOrderNewest ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
      });
      setState(() {});
    }
  }

  Future<List<Paper>> suggestedPapers() async {
    var maxRetries = 10;
    List<Paper> suggested = [];

    while (suggested.isEmpty && maxRetries > 0) {
      suggested = await Arxiv.suggest(pageSize: maxContent);
      maxRetries--;
    }
    return suggested;
  }

  // ------------------------------
  // PDF LOGIC
  // ------------------------------
  var paperTitle = "";
  var savePath = "";
  var pdfURL = "";

  Future<void> parseAndLaunchURL(String currentURL, String title) async {
    paperTitle = title;

    var splitURL = currentURL.split("/");
    var id = splitURL.last;

    var urlType = 0;

    if (id.contains(".")) {
      pdfURL = "$pdfBaseURL/$id";
      urlType = 1;
    } else {
      pdfURL = "$pdfBaseURL/cond-mat/$id";
      urlType = 2;
    }

    final Uri parsedURL = Uri.parse(pdfURL);
    savePath = '${(await getTemporaryDirectory()).path}/paper3.pdf';

    if (urlType == 2) {
      var result = await dio.downloadUri(parsedURL, savePath);
      if (result.statusCode != 200) {}
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewer(
          paperTitle: paperTitle,
          savePath: savePath,
          pdfURL: pdfURL,
          urlType: urlType,
          downloadPaper: downloadPaper,
        ),
      ),
    );
  }

  void downloadPaper(String paperURL) async {
    var splitURL = paperURL.split("/");
    var id = splitURL.last;
    var selectedURL = "";

    if (id.contains(".")) {
      selectedURL = "$pdfBaseURL/$id";
    } else {
      selectedURL = "$pdfBaseURL/cond-mat/$id";
    }

    await launchUrl(Uri.parse(selectedURL));
  }

  @override
  void initState() {
    super.initState();
    search();
  }

  @override
  void dispose() {
    searchTermController.dispose();
    super.dispose();
  }

  // ------------------------------
  // GET BODY WIDGET BASED ON NAV INDEX
  // ------------------------------
  Widget getBody() {
    switch (_selectedIndex) {
      case 0:
      // HOME
        return LiquidPullToRefresh(
          onRefresh: search,
          backgroundColor: Colors.white,
          color: const Color(0xff121212),
          animSpeedFactor: 2.0,
          child: ListView(
            children: [
              SearchBox(
                searchTermController: searchTermController,
                searchFunction: search,
                toggleSortOrder: toggleSortOrder,
                sortOrderNewest: sortOrderNewest,
              ),
              isHomeScreenLoading
                  ? const LoadingIndicator(topPadding: 200.0)
                  : data.isNotEmpty
                  ? Column(
                children: data.map((eachPaper) {
                  return EachPaperCard(
                    eachPaper: eachPaper,
                    downloadPaper: downloadPaper,
                    parseAndLaunchURL: parseAndLaunchURL,
                    isBookmarked: false,
                  );
                }).toList(),
              )
                  : const Padding(
                padding: EdgeInsets.only(top: 200),
                child: Center(
                  child: Text("No Results Found!"),
                ),
              ),
              const SizedBox(height: 20),
              // Pagination controls
              data.isNotEmpty && searchTermController.text.trim() != ""
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (startPagination >= paginationGap) {
                        startPagination -= paginationGap;
                        search();
                      }
                    },
                    icon: Icon(
                      Ionicons.arrow_back,
                      color: startPagination < paginationGap
                          ? Colors.white
                          : Colors.grey[400],
                    ),
                  ),
                  Text(
                    "Showing results from $startPagination to ${startPagination + maxContent}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  IconButton(
                    onPressed: () {
                      startPagination += paginationGap;
                      search();
                    },
                    icon: Icon(
                      Ionicons.arrow_forward,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              )
                  : Container(),
              // Footer
              Container(
                padding: const EdgeInsets.only(top: 200, bottom: 40),
                child: Center(
                  child: Text(
                    "Thank you to arXiv for use of its \nopen access interoperability.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(sourceCodeURL)),
                  child: const Text(
                    "View Source Code on GitHub",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    "Made with 🤍 by Dream Intelligence",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      case 1:
      // BOOKMARKS
        return BookmarksPage(
          downloadPaper: downloadPaper,
          parseAndLaunchURL: parseAndLaunchURL,
        );
      case 2:
      // AI CHAT
        return const AIChatPage(paperData: null);
      case 3:
      // CAMPUS
        return GWUStorePage(); // <-- NO const here
      default:
        return Container();
    }
  }

  // ------------------------------
  // UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
        ThemeProvider.themeOf(context).data.appBarTheme.backgroundColor,
        title: const Text("GWU-Arxiv"),
        actions: [
          // HELP
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HowToUsePage()),
              );
            },
            icon: const Icon(Icons.help_outline),
          ),
          // CHANGE THEME
          IconButton(
            onPressed: () {
              ThemeProvider.controllerOf(context).nextTheme();
            },
            icon: Icon(
              ThemeProvider.themeOf(context).id == "light_theme"
                  ? Icons.dark_mode_outlined
                  : ThemeProvider.themeOf(context).id == "dark_theme"
                  ? Icons.sunny_snowing
                  : Ionicons.sunny,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_outlined),
            label: "Bookmarks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            label: "AI Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: "Campus",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: "Plagiarism",
          ),
        ],
      ),
    );
  }
}
