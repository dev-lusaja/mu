// lang.js fills in the data-i18n text and renders the language buttons; this hook adds
// the index-only content from content.js on each switch.
window.onLanguageChanged = function (lang) {
    renderDownloads();
    loadWidgetRankings();
};

async function checkServerStatus() {
    const dot = document.getElementById('indexStatusDot');
    const text = document.getElementById('indexStatusText');
    const t = window.t();

    try {
        const res = await fetch('/api/public/server-status');
        const data = await res.json();
        if (data.online) {
            if (dot) dot.className = 'status-dot-box online';
            if (text) {
                text.className = 'status-value online';
                text.innerText = t.online || 'Online';
            }
        } else {
            if (dot) dot.className = 'status-dot-box offline';
            if (text) {
                text.className = 'status-value offline';
                text.innerText = t.offline || 'Offline';
            }
        }
    } catch {
        if (dot) dot.className = 'status-dot-box offline';
        if (text) {
            text.className = 'status-value offline';
            text.innerText = t.offline || 'Offline';
        }
    }
}

async function checkOnlinePlayers() {
    const text = document.getElementById('indexPlayersText');
    if (!text) return;

    try {
        const res = await fetch('/api/public/online-players');
        const data = await res.json();
        text.innerText = data.playerCount !== null ? data.playerCount : '---';
    } catch {
        text.innerText = '---';
    }
}

async function loadWidgetRankings() {
    const container = document.getElementById('widgetPlayersList');
    if (!container) return;

    try {
        const res = await fetch('/api/public/ranking');
        if (!res.ok) throw new Error('Ranking error');
        const players = await res.json();

        if (!players || players.length === 0) {
            container.innerHTML = '<p class="armory-message">No ranking data.</p>';
            return;
        }

        const topPlayers = players.slice(0, 5);
        let html = '<table class="mini-table"><thead><tr><th>#</th><th>Name</th><th>Class</th><th>Level</th><th>Resets</th></tr></thead><tbody>';

        topPlayers.forEach((p, idx) => {
            const rankClass = idx === 0 ? 'gold' : (idx === 1 ? 'silver' : (idx === 2 ? 'bronze' : ''));
            html += `<tr>
                <td><span class="rank-num ${rankClass}">${idx + 1}</span></td>
                <td class="char-name">${p.name || 'Hero'}</td>
                <td>${p.className || p.characterClass || 'Class'}</td>
                <td><b>${p.level}</b></td>
                <td><span class="reset-badge">${p.resets} RR</span></td>
            </tr>`;
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    } catch {
        container.innerHTML = '<p class="armory-message">Unable to load rankings.</p>';
    }
}

function switchWidgetTab(tab) {
    const btnPlayers = document.getElementById('btnTopPlayers');
    const btnGuilds = document.getElementById('btnTopGuilds');
    const listPlayers = document.getElementById('widgetPlayersList');
    const listGuilds = document.getElementById('widgetGuildsList');

    if (tab === 'players') {
        btnPlayers.classList.add('active');
        btnGuilds.classList.remove('active');
        listPlayers.classList.remove('hidden');
        listGuilds.classList.add('hidden');
    } else {
        btnGuilds.classList.add('active');
        btnPlayers.classList.remove('active');
        listGuilds.classList.remove('hidden');
        listPlayers.classList.add('hidden');
    }
}

const charClassData = {
    dw: {
        name: "Dark Wizard",
        image: "/img/sm_profile.jpeg",
        desc: "Masters of elemental offensive spellcraft. The Dark Wizard unleashes devastating area-of-effect spells like Evil Spirit and Flame to annihilate enemy hordes from a distance.",
        stats: [95, 45, 80]
    },
    dk: {
        name: "Dark Knight",
        image: "/img/dk_profile.jpeg",
        desc: "Fierce melee warriors forged in battle. With immense physical strength and heavy armor, the Dark Knight commands close-quarters combat with powerful sword skills.",
        stats: [50, 95, 70]
    },
    fe: {
        name: "Fairy Elf",
        image: "/img/fe_profile.jpeg",
        desc: "Agile archers and noble buffer priestesses of Noria. The Fairy Elf excels in long-range precision marksmanship and supportive elemental magic.",
        stats: [85, 60, 90]
    },
    mg: {
        name: "Magic Gladiator",
        image: "/img/mg_profile.jpeg",
        desc: "A unique dual-class warrior capable of wielding both heavy martial weaponry and destructive wizardry. MG fast-tracks leveling with unyielding offensive power.",
        stats: [90, 75, 85]
    },
    dl: {
        name: "Dark Lord",
        image: "/img/dl_profile.jpeg",
        desc: "Commanders of Valley of Loren. Leading armies with high Lord Leadership, Dark Lords summon the Dark Raven and Dark Horse to dominate the battlefield.",
        stats: [88, 85, 75]
    },
    sum: {
        name: "Summoner",
        image: "/img/dm_profile.jpeg",
        desc: "Wielders of ancient dark curses and mysterious summons. Summoners drain enemy vitality while casting debilitating spells upon opponents.",
        stats: [92, 50, 85]
    }
};

function selectCharClass(key, btnElem) {
    const data = charClassData[key];
    if (!data) return;

    document.querySelectorAll('.char-tab').forEach(b => b.classList.remove('active'));
    if (btnElem) btnElem.classList.add('active');

    document.getElementById('charClassName').innerText = data.name;
    document.getElementById('charClassDesc').innerText = data.desc;
    document.getElementById('statFill1').style.width = data.stats[0] + '%';
    document.getElementById('statFill2').style.width = data.stats[1] + '%';
    document.getElementById('statFill3').style.width = data.stats[2] + '%';

    const showcaseImg = document.getElementById('charShowcaseImg');
    if (showcaseImg && data.image) {
        showcaseImg.src = data.image;
        showcaseImg.alt = data.name;
    }
}

function renderDownloads() {
    const area = document.getElementById('downloadArea');
    if (!area) return;
    const t = window.t();
    const launcherUrl = window.muConfig && window.muConfig.launcherUrl;
    const items = (window.muConfig.downloads || []).map(d => {
        const isLauncher = d.id === 'launcher';
        const url = (isLauncher && launcherUrl) ? launcherUrl : d.url;
        const cls = d.recommended ? 'recommended' : (d.soon ? 'soon' : '');
        const tag = d.recommended ? `<span class="dlC-tag">${t.dlRecommended}</span>`
            : (d.soon ? `<span class="dlC-tag">${t.dlSoon}</span>` : '');
        const targetAttr = (!d.soon && (isLauncher || d.target === '_blank')) ? ' target="_blank" rel="noopener noreferrer"' : '';
        return `<a class="dlC-item ${cls}" href="${d.soon ? '#' : url}"${targetAttr}><div class="dlC-item-left"><span>${d.icon}</span> <span>${d.name}</span></div>${tag}</a>`;
    }).join('');

    area.innerHTML = `
        <div class="dlC-wrap" id="dlCWrap">
            <div class="dlC-trigger dl-gold" id="dlCTrigger">
                <span>⬇ ${t.dlDownload}</span><span class="dlC-caret">▼</span>
            </div>
            <div class="dlC-menu">${items}</div>
        </div>`;

    document.getElementById('dlCTrigger').addEventListener('click', e => {
        e.stopPropagation();
        document.getElementById('dlCWrap').classList.toggle('open');
    });
}

document.addEventListener('click', () => {
    const wrap = document.getElementById('dlCWrap');
    if (wrap) wrap.classList.remove('open');
});

function updateServerClock() {
    const clock = document.getElementById('serverClock');
    if (!clock) return;
    try {
        const now = new Date();
        const options = {
            timeZone: 'America/Lima',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        };
        clock.innerText = now.toLocaleTimeString('es-PE', options);
    } catch {
        const now = new Date();
        clock.innerText = now.toTimeString().split(' ')[0];
    }
}

updateServerClock();
setInterval(updateServerClock, 1000);

checkServerStatus();
checkOnlinePlayers();
loadWidgetRankings();
setInterval(checkServerStatus, 30000);
setInterval(checkOnlinePlayers, 30000);
