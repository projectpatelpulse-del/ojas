import 'dart:html' as html;

void updateFaviconLink(String url) {
  final links = html.document.getElementsByTagName('link');
  html.LinkElement? faviconLink;
  
  for (var i = 0; i < links.length; i++) {
    final link = links[i] as html.LinkElement;
    if (link.rel == 'icon' || link.rel == 'shortcut icon') {
      faviconLink = link;
      break;
    }
  }
  
  if (faviconLink != null) {
    faviconLink.href = url;
  } else {
    final newLink = html.LinkElement()
      ..rel = 'icon'
      ..href = url;
    html.document.head?.append(newLink);
  }
}
