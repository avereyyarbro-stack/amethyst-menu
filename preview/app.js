const CATEGORIES = [
  {
    id: "informational",
    label: "informational mods",
    mods: [
      {
        id: "enemy_health_numbers",
        title: "enemy team health numbers",
        description: "display numeric hp above enemy robots",
      },
      {
        id: "anaksor_invis_highlight",
        title: "anaksor invisibility highlight",
        description: "outline anaksor while stealth is active",
      },
    ],
  },
  {
    id: "layouts",
    label: "layouts",
    mods: [
      {
        id: "layout_robot_slots",
        title: "log robot slots",
        description: "record hangar slot ids to layouts.log",
      },
      {
        id: "layout_slot_robots",
        title: "log slot robots",
        description: "record robot name/id per slot",
      },
      {
        id: "layout_robot_weapons",
        title: "log robot weapons",
        description: "record equipped weapons per robot",
      },
      {
        id: "layout_titan_weapons",
        title: "log titan weapons",
        description: "record titan and titan weapon loadout",
      },
    ],
  },
];

const STORAGE_KEY = "amethyst_mods";
const LOG_KEY = "amethyst_layout_log";

function loadState() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}");
  } catch {
    return {};
  }
}

function saveState(state) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function appendLayoutLog(entry) {
  const existing = localStorage.getItem(LOG_KEY) || "";
  localStorage.setItem(LOG_KEY, `${existing}${JSON.stringify(entry)}\n`);
}

function buildDemoLayoutSnapshot(enabledIds) {
  return {
    timestamp: new Date().toISOString(),
    category: "layouts",
    enabled_loggers: enabledIds,
    robot_slots: [{ slot: 1, robot: "demo-nashorn", weapons: ["punisher", "pin"] }],
    slot_robots: [{ slot: 1, robot: "demo-nashorn" }],
    robot_weapons: [{ slot: 1, weapons: ["punisher", "pin"] }],
    titan_weapons: [{ titan: "demo-kid", weapons: ["retaliator"] }],
    note: "browser preview demo data",
  };
}

function renderToggles() {
  const container = document.getElementById("toggles");
  const state = loadState();
  container.innerHTML = "";

  for (const category of CATEGORIES) {
    const heading = document.createElement("p");
    heading.className = "section-label";
    heading.textContent = category.label;
    container.appendChild(heading);

    for (const mod of category.mods) {
      const enabled = Boolean(state[mod.id]);
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "toggle-row";
      btn.innerHTML = `
        <div class="toggle-copy">
          <div class="toggle-title">${mod.title}</div>
          <div class="toggle-desc">${mod.description}</div>
        </div>
        <div class="indicator ${enabled ? "on" : ""}" aria-hidden="true"></div>
      `;
      btn.addEventListener("click", () => {
        state[mod.id] = !state[mod.id];
        saveState(state);
        if (category.id === "layouts" && state[mod.id]) {
          const enabled = category.mods.filter((m) => state[m.id]).map((m) => m.id);
          appendLayoutLog(buildDemoLayoutSnapshot(enabled));
          document.getElementById("terminal").innerHTML =
            `$ layouts -> localStorage (${LOG_KEY})<span class="cursor">█</span>`;
        }
        renderToggles();
      });
      container.appendChild(btn);
    }
  }
}

function updateTimestamp() {
  const el = document.getElementById("timestamp");
  const now = new Date();
  el.textContent = now.toISOString().slice(0, 19).replace("T", " ");
}

function drawWaves() {
  const canvas = document.getElementById("waves");
  const ctx = canvas.getContext("2d");
  const dpr = window.devicePixelRatio || 1;

  canvas.width = window.innerWidth * dpr;
  canvas.height = window.innerHeight * dpr;
  ctx.scale(dpr, dpr);

  ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
  ctx.strokeStyle = "rgba(255,255,255,0.04)";
  ctx.lineWidth = 1;

  for (let y = 0; y < window.innerHeight; y += 28) {
    ctx.beginPath();
    for (let x = 0; x <= window.innerWidth; x += 8) {
      const wave = Math.sin((x + y) * 0.02) * 3;
      if (x === 0) ctx.moveTo(x, y + wave);
      else ctx.lineTo(x, y + wave);
    }
    ctx.stroke();
  }
}

renderToggles();
updateTimestamp();
drawWaves();
setInterval(updateTimestamp, 1000);
window.addEventListener("resize", drawWaves);

const panel = document.getElementById("panel");
document.getElementById("openMenu").addEventListener("click", () => {
  panel.classList.remove("hidden");
});
document.getElementById("closeMenu").addEventListener("click", () => {
  panel.classList.add("hidden");
});
document.getElementById("logLayouts").addEventListener("click", () => {
  const state = loadState();
  const enabled = CATEGORIES.find((c) => c.id === "layouts").mods
    .filter((m) => state[m.id])
    .map((m) => m.id);
  if (!enabled.length) {
    document.getElementById("terminal").innerHTML =
      `$ enable a layouts toggle first<span class="cursor">█</span>`;
    return;
  }
  appendLayoutLog(buildDemoLayoutSnapshot(enabled));
  document.getElementById("terminal").innerHTML =
    `$ layouts -> localStorage (${LOG_KEY})<span class="cursor">█</span>`;
});
