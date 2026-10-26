const DEFAULT_SITES = ["mangadex.org", "manganato.com", "readmanga.app", "mangakakalot.com"];

document.addEventListener("DOMContentLoaded", () => {
  loadSites();

  document.getElementById("addDomain").addEventListener("click", addSite);
  document.getElementById("testConnection").addEventListener("click", checkConnection);
});

function loadSites() {
  browser.storage.local.get({ allowedSites: DEFAULT_SITES }).then((result) => {
    renderSiteList(result.allowedSites);
  });
}

function renderSiteList(sites) {
  const ul = document.getElementById("siteList");
  ul.innerHTML = "";

  sites.forEach((site) => {
    const li = document.createElement("li");
    li.className = "site-item";

    const span = document.createElement("span");
    span.textContent = site;

    const btn = document.createElement("button");
    btn.textContent = "Remove";
    btn.className = "remove-btn";
    btn.addEventListener("click", () => removeSite(site));

    li.appendChild(span);
    li.appendChild(btn);
    ul.appendChild(li);
  });
}

function addSite() {
  const input = document.getElementById("newDomain");
  const domain = input.value.trim().toLowerCase().replace(/^https?:\/\//, "").replace(/\/.*$/, "");

  if (!domain) return;

  browser.storage.local.get({ allowedSites: DEFAULT_SITES }).then((result) => {
    const sites = result.allowedSites;
    if (!sites.includes(domain)) {
      sites.push(domain);
      browser.storage.local.set({ allowedSites: sites }).then(() => {
        input.value = "";
        renderSiteList(sites);
      });
    }
  });
}

function removeSite(siteToRemove) {
  browser.storage.local.get({ allowedSites: DEFAULT_SITES }).then((result) => {
    const sites = result.allowedSites.filter((s) => s !== siteToRemove);
    browser.storage.local.set({ allowedSites: sites }).then(() => {
      renderSiteList(sites);
    });
  });
}

function checkConnection() {
  const statusDiv = document.getElementById("connectionStatus");
  statusDiv.textContent = "Connecting to app...";
  statusDiv.className = "status";

  fetch("http://127.0.0.1:8080/status")
    .then((res) => res.json())
    .then((data) => {
      if (data.status === "running") {
        statusDiv.textContent = `Online! Connected to Manga Tracker (${data.mangaCount} mangas in library).`;
        statusDiv.className = "status online";
      } else {
        statusDiv.textContent = "Unexpected response from app server.";
        statusDiv.className = "status offline";
      }
    })
    .catch(() => {
      statusDiv.textContent = "Offline! Is Manga Tracker app open on your phone?";
      statusDiv.className = "status offline";
    });
}
