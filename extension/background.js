const DEFAULT_SITES = ["mangadex.org", "manganato.com", "readmanga.app", "mangakakalot.com"];

// Cache of tab ID -> last visited URL
const tabUrlMap = new Map();

// Track active tab URL updates
browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (tab.url) {
    tabUrlMap.set(tabId, tab.url);
  }
});

// Handle tab close event
browser.tabs.onRemoved.addListener((tabId, removeInfo) => {
  const url = tabUrlMap.get(tabId);
  tabUrlMap.delete(tabId);

  if (!url) return;

  browser.storage.local.get({ allowedSites: DEFAULT_SITES }).then((result) => {
    const allowedSites = result.allowedSites || DEFAULT_SITES;

    // Check if the closed tab URL matches any allowed site
    const isAllowedSite = allowedSites.some((site) => url.toLowerCase().includes(site.toLowerCase()));

    if (isAllowedSite) {
      processAndSendMangaData(url);
    }
  });
});

/**
 * Extracts manga title slug and chapter number from a URL.
 * Example URLs:
 *  - https://mangadex.org/chapter/abc1234/1081
 *  - https://mangadex.org/title/manga-uuid/one-piece
 *  - https://manganato.com/manga-ab12345/chapter-1081
 *  - https://site.com/manga/jujutsu-kaisen/chapter-240
 */
function processAndSendMangaData(url) {
  try {
    const parsed = parseMangaUrl(url);
    if (!parsed || !parsed.title || !parsed.chapter) {
      console.log("Manga Tracker Sync: Could not parse title/chapter from URL:", url);
      return;
    }

    console.log("Manga Tracker Sync: Sending data to app:", parsed);

    fetch("http://127.0.0.1:8080/update", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        title: parsed.title,
        chapter: parsed.chapter,
        url: url
      })
    })
    .then((res) => res.json())
    .then((data) => {
      console.log("Manga Tracker Sync Response:", data);
    })
    .catch((err) => {
      console.warn("Manga Tracker Sync: Could not reach app server at http://127.0.0.1:8080 -", err);
    });
  } catch (e) {
    console.error("Manga Tracker Sync error:", e);
  }
}

function parseMangaUrl(urlString) {
  const url = new URL(urlString);
  const pathname = url.pathname.toLowerCase();

  // Pattern 1: .../chapter-1081 or .../c1081 or .../chapter/1081
  const chapterMatch = pathname.match(/(?:chapter|chap|c)[-/_]?([0-9]+(?:\.[0-9]+)?)/i);
  let chapter = chapterMatch ? parseFloat(chapterMatch[1]) : null;

  if (!chapter) {
    // Check path segments for numbers
    const parts = pathname.split("/").filter(Boolean);
    for (let i = parts.length - 1; i >= 0; i--) {
      const num = parseFloat(parts[i]);
      if (!isNaN(num) && num > 0 && num < 5000) {
        chapter = num;
        break;
      }
    }
  }

  // Extract title slug
  // Path parts e.g. ["manga", "one-piece", "chapter-1081"]
  const parts = pathname.split("/").filter(Boolean);
  let titleSlug = "";

  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    // Skip generic keywords
    if (["manga", "title", "series", "read", "comic", "chapter"].includes(part)) continue;
    if (part.match(/^(?:chapter|chap|c)[-/_]?[0-9]+/i)) continue;
    if (!isNaN(parseFloat(part)) && parseFloat(part) === chapter) continue;

    titleSlug = part;
    break;
  }

  // Clean up title slug (e.g. "manga-ab1234" -> "ab1234", "one-piece-manga" -> "one-piece")
  titleSlug = titleSlug.replace(/^(manga|read)-/, "").replace(/-(manga|read)$/, "");

  if (titleSlug && chapter) {
    return {
      title: titleSlug,
      chapter: Math.floor(chapter)
    };
  }

  return null;
}
