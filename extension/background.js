const DEFAULT_SITES = [
  "mangadex.org",
  "manganato.com",
  "readmanga.app",
  "mangakakalot.com",
  "mgeko.cc",
  "manganami.com"
];

// List of URL path keywords that are NOT manga pages
const IGNORED_PATHS = [
  "about", "privacy", "terms", "login", "register", "contact", "faq",
  "search", "user", "profile", "bookmark", "bookmarks", "history", "home",
  "genre", "genres", "tag", "tags", "author", "authors", "group", "groups"
];

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// In-memory cache of allowed sites for 0ms instant tab closure checks
let cachedAllowedSites = [...DEFAULT_SITES];

browser.storage.local.get({ allowedSites: DEFAULT_SITES }).then((result) => {
  if (result && result.allowedSites) {
    cachedAllowedSites = result.allowedSites;
  }
});

browser.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.allowedSites) {
    cachedAllowedSites = changes.allowedSites.newValue || DEFAULT_SITES;
  }
});

// Periodic heartbeat ping to app server every 15 seconds
function sendHeartbeatPing() {
  fetch("http://127.0.0.1:8080/ping")
    .then((res) => res.json())
    .catch(() => {});
}

setInterval(sendHeartbeatPing, 15000);
sendHeartbeatPing();

// Cache of tab ID -> last visited URL
const tabUrlMap = new Map();

browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (tab.url) {
    tabUrlMap.set(tabId, tab.url);
  }
});

browser.tabs.onRemoved.addListener((tabId, removeInfo) => {
  const url = tabUrlMap.get(tabId);
  tabUrlMap.delete(tabId);

  if (!url) return;

  // Instant synchronous check using in-memory cached site list
  const isAllowedSite = cachedAllowedSites.some((site) => url.toLowerCase().includes(site.toLowerCase()));

  if (isAllowedSite) {
    processAndSendMangaData(url);
  }
});

/**
 * Parses manga URL and sends instant HTTP POST update to app server.
 */
function processAndSendMangaData(url) {
  try {
    const parsed = parseMangaUrl(url);
    if (!parsed || !parsed.title) {
      console.log("Manga Tracker Sync: Ignored non-manga URL:", url);
      return;
    }

    console.log("Manga Tracker Sync: Sending instant update to app:", parsed);

    fetch("http://127.0.0.1:8080/update", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        title: parsed.title,
        chapter: parsed.chapter,
        isChapter: parsed.isChapter,
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
  try {
    const url = new URL(urlString);
    const pathname = url.pathname.toLowerCase();
    const search = url.search.toLowerCase();
    const fullPath = pathname + search;

    const pathParts = pathname.split("/").filter(Boolean);
    if (pathParts.length === 0) return null; // Homepage
    if (pathParts.some((p) => IGNORED_PATHS.includes(p))) return null;

    // Pattern A: Combined title + chapter in single path segment
    // e.g. /reader/en/a-wimps-strategy-guide-to-conquer-the-tower-chapter-52-eng-li/
    for (let i = 0; i < pathParts.length; i++) {
      const part = pathParts[i];
      if (["manga", "title", "series", "read", "reader", "en", "comic"].includes(part)) continue;

      const combinedMatch = part.match(/^(.+?)[-_]chapter[-_]([0-9]+(?:\.[0-9]+)?)(?:[-_].*)?$/i);
      if (combinedMatch) {
        let titleSlug = combinedMatch[1]
          .replace(/-(?:[a-z0-9]{4,7})$/i, "")
          .replace(/^(manga|read)-/, "")
          .replace(/-(manga|read)$/, "")
          .trim();
        const chapterNum = parseFloat(combinedMatch[2]);

        if (titleSlug && !isNaN(chapterNum) && chapterNum > 0) {
          return {
            title: titleSlug,
            chapter: Math.floor(chapterNum),
            isChapter: true
          };
        }
      }
    }

    // Pattern B: Explicit chapter indicator in separate path/query
    // e.g. /manga/cheonhwa-archives-young-master/chapter-188 or /chapter/1081
    const chapterMatch = fullPath.match(/(?:chapter|chap|ch|c)[-/_=]?([0-9]+(?:\.[0-9]+)?)/i);
    const isChapter = !!chapterMatch;
    let chapterNum = 1;

    if (chapterMatch) {
      const parsedNum = parseFloat(chapterMatch[1]);
      if (!isNaN(parsedNum) && parsedNum > 0) {
        chapterNum = Math.floor(parsedNum);
      }
    }

    // Extract title slug
    let titleSlug = "";
    for (let i = 0; i < pathParts.length; i++) {
      const part = pathParts[i];
      if (["manga", "title", "series", "read", "reader", "en", "comic", "chapter", "chap", "ch"].includes(part)) continue;
      if (part.match(/^(?:chapter|chap|ch|c)[-/_]?[0-9]+/i)) continue;
      if (UUID_REGEX.test(part)) continue;
      if (!isNaN(parseFloat(part))) continue;

      titleSlug = part;
      break;
    }

    titleSlug = titleSlug
      .replace(/-(?:[a-z0-9]{4,7})$/i, "")
      .replace(/^(manga|read)-/, "")
      .replace(/-(manga|read)$/, "")
      .trim();

    if (!titleSlug || titleSlug.length < 2) return null;

    return {
      title: titleSlug,
      chapter: chapterNum,
      isChapter: isChapter
    };
  } catch (e) {
    return null;
  }
}
