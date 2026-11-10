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
  "genre", "genres", "tag", "tags", "author", "authors", "group", "groups",
  "jumbo", "latest", "directory", "popular"
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

// FORCE-sync all tabs aggressively every 5 seconds
function syncAllOpenTabs() {
  if (browser.tabs && browser.tabs.query) {
    browser.tabs.query({}).then((tabs) => {
      if (tabs) {
        tabs.forEach((tab) => {
          if (tab.id && tab.url && tab.url.startsWith("http")) {
            tabUrlMap.set(tab.id, tab.url);
          }
        });
      }
    }).catch(() => {});
  }
}

syncAllOpenTabs();
setInterval(syncAllOpenTabs, 5000);

// Watch for any created tab and immediately grab its pending or committed URL
browser.tabs.onCreated.addListener((tab) => {
  const url = tab.url || tab.pendingUrl;
  if (tab.id && url && url.startsWith("http")) {
    tabUrlMap.set(tab.id, url);
  }
});

// Update map continuously as tabs navigate
browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  const url = changeInfo.url || tab.url || tab.pendingUrl;
  if (url && url.startsWith("http")) {
    tabUrlMap.set(tabId, url);
  }
});

// TRIPLE-CHECK fallback when tab is closed
browser.tabs.onRemoved.addListener(async (tabId, removeInfo) => {
  let url = tabUrlMap.get(tabId);
  tabUrlMap.delete(tabId);

  if (!url) {
    try {
      if (browser.sessions && browser.sessions.getRecentlyClosed) {
        const sessions = await browser.sessions.getRecentlyClosed({ maxResults: 10 });
        if (sessions) {
          for (const session of sessions) {
            if (session.tab && session.tab.url && session.tab.url.startsWith("http")) {
              const isAllowed = cachedAllowedSites.some((site) => session.tab.url.toLowerCase().includes(site.toLowerCase()));
              if (isAllowed) {
                url = session.tab.url;
                break;
              }
            }
          }
        }
      }
    } catch (e) {}
  }

  if (!url) {
    try {
      if (browser.history && browser.history.search) {
        const historyItems = await browser.history.search({ text: "", maxResults: 10 });
        if (historyItems) {
          for (const item of historyItems) {
            if (item.url && item.url.startsWith("http")) {
              const isAllowed = cachedAllowedSites.some((site) => item.url.toLowerCase().includes(site.toLowerCase()));
              if (isAllowed) {
                url = item.url;
                break;
              }
            }
          }
        }
      }
    } catch (e) {}
  }

  if (!url) return;

  const isAllowedSite = cachedAllowedSites.some((site) => url.toLowerCase().includes(site.toLowerCase()));

  if (isAllowedSite) {
    processAndSendMangaData(url);
  }
});

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

/**
 * Cleans prefix site hashes (e.g. U23q-, K235K-, k798lLM-, 482q-, 4gp-, a12b-)
 * while preserving real words, plain numbers (100), and ordinals (13th, 3rd, 1st).
 */
function cleanTitleSlug(slug) {
  if (!slug) return "";
  let clean = slug.trim();

  // Strip random hash suffixes and language tags from the end FIRST
  clean = clean
    .replace(/-(?:eng|li|raw|sub|dub|v[0-9]+)$/gi, "")
    .replace(/-(?:[a-z0-9]{3,7})$/gi, "")
    .replace(/^(manga|read|comic)-/i, "")
    .replace(/-(manga|read|comic)$/i, "")
    .trim();

  const parts = clean.split(/[-_]/).filter(Boolean);
  if (parts.length > 1) {
    const first = parts[0];

    const isOrdinal = /^[0-9]+(st|nd|rd|th)$/i.test(first);
    const isPlainNumber = /^[0-9]+$/.test(first);
    const isCommonWord = /^(the|a|an|in|on|at|to|for|of|is|i|my|our)$/i.test(first);

    // Strict check for prefix hashes: must contain at least one number AND at least one letter, exactly 3-8 chars.
    // If it's longer than 8 characters (e.g. "reincarnators"), it's definitely a real word and NOT a prefix hash!
    const isMixedCode = /^(?=[a-z0-9]*[0-9])(?=[a-z0-9]*[a-z])[a-z0-9]{3,8}$/i.test(first);

    // Completely generic random letter sequence that shouldn't start a sentence (like "mcqyg")
    const isRandomGibberish = /^[a-z]{4,6}$/i.test(first) && !isCommonWord && !/^(solo|return|hero|tower|player|rank|god|king|demon|magic|sword|reincarnators?)$/i.test(first);

    if ((isMixedCode || isRandomGibberish) && !isOrdinal && !isPlainNumber && !isCommonWord) {
      parts.shift();
      clean = parts.join("-");
    }
  }

  // Restore 's suffix which may have been split by regex dashes
  clean = clean.replace(/-s\b/g, "'s");

  return clean;
}

function parseMangaUrl(urlString) {
  try {
    const url = new URL(urlString);
    const pathname = url.pathname.toLowerCase();
    const search = url.search.toLowerCase();
    const fullPath = pathname + search;

    if (pathname.includes("/jumbo/manga") || pathname.includes("/jumbo")) {
      return null;
    }

    const pathParts = pathname.split("/").filter(Boolean);
    if (pathParts.length === 0) return null;
    if (pathParts.some((p) => IGNORED_PATHS.includes(p))) return null;

    // Pattern A: Combined title + chapter in single path segment
    // e.g. /reader/en/reincarnators-stream-chapter-71-eng-li/
    for (let i = 0; i < pathParts.length; i++) {
      const part = pathParts[i];
      if (["manga", "title", "series", "read", "reader", "en", "comic"].includes(part)) continue;

      const combinedMatch = part.match(/^(.+?)[-_]chapter[-_]([0-9]+(?:\.[0-9]+)?)(?:[-_].*)?$/i);
      if (combinedMatch) {
        const titleSlug = cleanTitleSlug(combinedMatch[1]);
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
    let rawTitleSlug = "";
    for (let i = 0; i < pathParts.length; i++) {
      const part = pathParts[i];
      if (["manga", "title", "series", "read", "reader", "en", "comic", "chapter", "chap", "ch"].includes(part)) continue;
      if (part.match(/^(?:chapter|chap|ch|c)[-/_]?[0-9]+/i)) continue;
      if (UUID_REGEX.test(part)) continue;
      if (!isNaN(parseFloat(part))) continue;

      rawTitleSlug = part;
      break;
    }

    const titleSlug = cleanTitleSlug(rawTitleSlug);
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
