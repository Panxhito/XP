const hud = document.getElementById('xp-hud');
const levelEl = document.getElementById('xp-level');
const totalEl = document.getElementById('xp-total');
const progressEl = document.getElementById('xp-progress');
const barEl = document.getElementById('xp-bar');
const prestigeEl = document.getElementById('xp-prestige');
const capEl = document.getElementById('xp-cap');
const topEl = document.getElementById('xp-top');

window.addEventListener('message', (event) => {
    const { action, payload } = event.data || {};

    if (action === 'toggle') {
        if (payload?.visible) hud.classList.remove('hidden');
        else hud.classList.add('hidden');
        return;
    }

    if (action === 'sync') {
        const level = payload?.level ?? 1;
        const totalXP = payload?.xp ?? 0;
        const currentXP = payload?.progressXP ?? 0;
        const nextXP = payload?.nextXP ?? 100;
        const prestige = payload?.prestige ?? 0;
        const maxLevel = payload?.maxLevel ?? 100;

        const percentage = nextXP > 0 ? Math.min(100, Math.floor((currentXP / nextXP) * 100)) : 100;

        levelEl.textContent = `Nivel ${level}`;
        totalEl.textContent = `${totalXP} XP`;
        progressEl.textContent = `${currentXP} / ${nextXP}`;
        prestigeEl.textContent = `Prestigio ${prestige}`;
        capEl.textContent = `MAX ${maxLevel}`;
        barEl.style.width = `${percentage}%`;
        return;
    }

    if (action === 'leaderboard') {
        if (!Array.isArray(payload) || payload.length === 0) {
            topEl.innerHTML = 'Sin datos de ranking';
            topEl.classList.remove('hidden');
            return;
        }

        topEl.innerHTML = payload
            .slice(0, 5)
            .map((row, i) => `#${i + 1} ${row.name || 'Unknown'} - Lv.${row.level} | XP ${row.xp} | P${row.prestige || 0}`)
            .join('<br>');

        topEl.classList.remove('hidden');
    }
});
