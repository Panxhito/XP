const hud = document.getElementById('xp-hud');
const levelEl = document.getElementById('xp-level');
const totalEl = document.getElementById('xp-total');
const progressEl = document.getElementById('xp-progress');
const barEl = document.getElementById('xp-bar');

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

        const percentage = nextXP > 0 ? Math.min(100, Math.floor((currentXP / nextXP) * 100)) : 100;

        levelEl.textContent = `Nivel ${level}`;
        totalEl.textContent = `${totalXP} XP`;
        progressEl.textContent = `${currentXP} / ${nextXP}`;
        barEl.style.width = `${percentage}%`;
    }
});
