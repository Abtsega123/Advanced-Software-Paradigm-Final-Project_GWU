import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GWUSite {
  final String name;
  final String url;
  final String description;
  final IconData icon; // Use Icon instead of image

  GWUSite({
    required this.name,
    required this.url,
    required this.description,
    required this.icon,
  });
}

class GWUStorePage extends StatelessWidget {
  GWUStorePage({super.key});

  final List<GWUSite> gwSites = [
    GWUSite(
      name: "Academic Commons",
      url: "https://gwtoday.gwu.edu/academic-commons-one-stop-shop-student-resources",
      description: "Central hub for tutoring, study spaces, writing help, and software.",
      icon: Icons.school,
    ),
    GWUSite(
      name: "Research Commons",
      url: "https://researchcommons.gwu.edu",
      description: "Find research opportunities, funding, and collaborate with peers.",
      icon: Icons.biotech,
    ),
    GWUSite(
      name: "GW Libraries – Research Guides",
      url: "https://libguides.gwu.edu",
      description: "Guided access to databases, journals, and subject-specific resources.",
      icon: Icons.menu_book,
    ),
    GWUSite(
      name: "Find It @ GWU",
      url: "https://libguides.gwu.edu/googlescholar/finditatgw",
      description: "Link Google Scholar searches to GW library subscriptions.",
      icon: Icons.search,
    ),
    GWUSite(
      name: "Academic Program Support",
      url: "https://studentsuccess.gwu.edu/academic-program-support",
      description: "Academic advising, coaching, and tutoring support.",
      icon: Icons.support_agent,
    ),
    GWUSite(
      name: "Student Research Resources",
      url: "https://researchshowcase.gwu.edu/resources",
      description: "Writing assistance, workshops, software, and research tools.",
      icon: Icons.psychology,
    ),
    GWUSite(
      name: "GW Writing Center",
      url: "https://gsehd.gwu.edu/student-success/dissertations",
      description: "Guidance for writing projects, research papers, and dissertations.",
      icon: Icons.create,
    ),
    GWUSite(
      name: "Engineering Databases",
      url: "https://libguides.gwu.edu/engineeringdatabases",
      description: "Access IEEE, ACM, Compendex, Knovel, and other engineering databases.",
      icon: Icons.memory,
    ),
    GWUSite(
      name: "Civil & Env Engineering Guide",
      url: "https://libguides.gwu.edu/civilengineering",
      description: "Journals, conferences, and resources for civil and environmental engineering.",
      icon: Icons.engineering,
    ),
    GWUSite(
      name: "Engineering Management Guide",
      url: "https://libguides.gwu.edu/engineering_management",
      description: "Engineering + business research, project management, and career growth.",
      icon: Icons.business_center,
    ),
    GWUSite(
      name: "GW OSPO",
      url: "https://ospo.gwu.edu",
      description: "Open Source Program Office for software development & open science.",
      icon: Icons.code,
    ),
    GWUSite(
      name: "LabArchives",
      url: "https://research.gwu.edu/labarchives",
      description: "Digital lab notebook for managing and sharing research data securely.",
      icon: Icons.book_online,
    ),
  ];

  Future<void> _openWebsite(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch $url");
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  void _showDescription(BuildContext context, GWUSite site) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(site.icon, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 15),
              Text(
                site.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                site.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openWebsite(site.url);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text("Open Website"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GWU Academic Hub"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          itemCount: gwSites.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final site = gwSites[index];
            return GestureDetector(
              onTap: () => _showDescription(context, site),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(site.icon, size: 50, color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    site.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
