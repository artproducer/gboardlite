// =========================================
// i18n
// =========================================
const i18n = {
    es: {
        headerSubtitle: 'KernelSU WebUI — gboardlite_apmods',
        statusTitle: 'Estado',
        verifyingModule: 'Verificando módulo...',
        themesLabel: 'Temas',
        executingCommand: 'Espera...',
        configureThemes: 'Configurar Temas',
        lightTheme: 'Tema Claro',
        darkTheme: 'Tema Oscuro',
        lightThemeLabel: 'Tema para modo claro:',
        darkThemeLabel: 'Tema para modo oscuro:',
        selectOption: 'Seleccionar...',
        applyBtn: 'Aplicar',
        systemLog: 'Log',
        clearBtn: 'Limpiar',
        copyLogBtn: 'Copiar',
        moduleFound: 'Módulo activo',
        moduleNotFound: 'Módulo no encontrado',
        selectBothThemes: 'Selecciona ambos temas',
        applyingThemes: 'Aplicando temas...',
        themesApplied: '¡Temas aplicados! Reinicia para ver los cambios.',
        configSaved: 'Configuración guardada',
        restartRequired: 'Reinicio necesario',
        applyError: 'Error al aplicar temas',
        logCleared: 'Log limpiado',
        logCopied: 'Log copiado',
        nothingToCopy: 'Nada que copiar',
        noRootDetected: 'Root no detectado',
        currentLightTheme: 'Tema claro:',
        currentDarkTheme: 'Tema oscuro:',
        notConfigured: 'No configurado',
        themesFound: 'Temas encontrados',
        noThemesFound: 'Sin temas disponibles',
        loadThemesError: 'Error cargando temas',
        verifyModuleFirst: 'Verifique el módulo primero',
        telegramBanner: '¡Únete a nuestro canal de Telegram!',
        donateBanner: 'Donar'
    },
    en: {
        headerSubtitle: 'KernelSU WebUI — gboardlite_apmods',
        statusTitle: 'Status',
        verifyingModule: 'Verifying module...',
        themesLabel: 'Themes',
        executingCommand: 'Please wait...',
        configureThemes: 'Configure Themes',
        lightTheme: 'Light Theme',
        darkTheme: 'Dark Theme',
        lightThemeLabel: 'Theme for light mode:',
        darkThemeLabel: 'Theme for dark mode:',
        selectOption: 'Select...',
        applyBtn: 'Apply',
        systemLog: 'Log',
        clearBtn: 'Clear',
        copyLogBtn: 'Copy',
        moduleFound: 'Module active',
        moduleNotFound: 'Module not found',
        selectBothThemes: 'Select both themes',
        applyingThemes: 'Applying themes...',
        themesApplied: 'Themes applied! Restart to see changes.',
        configSaved: 'Configuration saved',
        restartRequired: 'Restart required',
        applyError: 'Error applying themes',
        logCleared: 'Log cleared',
        logCopied: 'Log copied',
        nothingToCopy: 'Nothing to copy',
        noRootDetected: 'Root not detected',
        currentLightTheme: 'Light theme:',
        currentDarkTheme: 'Dark theme:',
        notConfigured: 'Not configured',
        themesFound: 'Themes found',
        noThemesFound: 'No themes available',
        loadThemesError: 'Error loading themes',
        verifyModuleFirst: 'Verify module first',
        telegramBanner: 'Join our Telegram channel!',
        donateBanner: 'Donate'
    }
};

let lang = localStorage.getItem('gboardLang') || 'en';

function t(key) {
    return i18n[lang]?.[key] || i18n.en[key] || key;
}

function applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        const val = i18n[lang]?.[key];
        if (val) el.textContent = val;
    });
    document.documentElement.lang = lang;
}

function toggleLanguage() {
    lang = lang === 'es' ? 'en' : 'es';
    localStorage.setItem('gboardLang', lang);
    const sw = document.getElementById('langSwitch');
    const es = document.getElementById('langEs');
    const en = document.getElementById('langEn');
    sw.classList.toggle('en', lang === 'en');
    es.classList.toggle('active', lang === 'es');
    en.classList.toggle('active', lang === 'en');
    applyTranslations();
    log(lang === 'en' ? 'Language → English' : 'Idioma → Español', 'info');
}

// =========================================
// State
// =========================================
let moduleActive = false;
let availableThemes = [];
const MODDIR = '/data/adb/modules/gboardlite_apmods';
const CONFIG_PATH = `${MODDIR}/system.prop`;
const WEBROOT_PATH = `${MODDIR}/webroot`;

// =========================================
// Log
// =========================================
const MAX_LOG_LINES = 60;

function log(msg, type = 'info') {
    const c = document.getElementById('logContainer');
    const el = document.createElement('div');
    const ts = new Date().toLocaleTimeString('en-US', { hour12: false });
    el.className = `log-line log-${type}`;
    el.textContent = `[${ts}] ${msg}`;
    c.appendChild(el);
    c.scrollTop = c.scrollHeight;
    while (c.children.length > MAX_LOG_LINES) c.removeChild(c.firstChild);
}

function clearLog() {
    document.getElementById('logContainer').innerHTML = '';
    log(t('logCleared'), 'info');
}

async function copyLog() {
    const lines = Array.from(document.getElementById('logContainer').children).map(l => l.textContent);
    const text = lines.join('\n');
    if (!text.trim()) { showAlert(t('nothingToCopy'), 'warning'); return; }
    try {
        await navigator.clipboard.writeText(text);
        showAlert(t('logCopied'), 'success');
    } catch {
        showAlert(t('logCopied'), 'warning');
    }
}

// =========================================
// UI Helpers
// =========================================
function showAlert(msg, type = 'success') {
    const id = `alert${type.charAt(0).toUpperCase() + type.slice(1)}`;
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = msg;
    el.style.display = 'block';
    setTimeout(() => el.style.display = 'none', 3500);
}

function showLoading(v) {
    document.getElementById('loading').style.display = v ? 'block' : 'none';
}

function setStatus(active, msg) {
    const el = document.getElementById('moduleStatus');
    moduleActive = active;
    el.className = `module-status ${active ? 'status-active' : 'status-inactive'}`;
    el.innerHTML = active
        ? `<svg class="icon" viewBox="0 0 24 24"><polyline points="20,6 9,17 4,12"/></svg> ${msg}`
        : `<svg class="icon" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg> ${msg}`;
}

function showCurrentConfig(lightTheme, darkTheme) {
    const cfgEl = document.getElementById('currentConfig');
    const cfgContent = document.getElementById('configContent');
    cfgContent.innerHTML = `
        <div style="font-size:12px;color:#94a3b8;margin-bottom:6px;">☀️ ${t('currentLightTheme')} <strong>${lightTheme || t('notConfigured')}</strong></div>
        <div class="config-line">ro.com.google.ime.theme_file=${lightTheme || ''}</div>
        <div style="font-size:12px;color:#94a3b8;margin:8px 0 6px;">🌙 ${t('currentDarkTheme')} <strong>${darkTheme || t('notConfigured')}</strong></div>
        <div class="config-line">ro.com.google.ime.d_theme_file=${darkTheme || ''}</div>
    `;
    cfgEl.style.display = 'block';
}

// =========================================
// KSU Shell
// =========================================
async function exec(cmd) {
    if (typeof ksu?.exec !== 'function') throw new Error('KSU API unavailable');
    const r = await ksu.exec(cmd);
    return r?.toString() || '';
}

// =========================================
// Telegram Banner (WebView compatible)
// =========================================
function openTelegram(e) {
    e.preventDefault();
    // Open Telegram via Android intent (non-blocking, detached)
    if (typeof ksu?.exec === 'function') {
        try {
            ksu.exec('nohup am start -a android.intent.action.VIEW -d "https://t.me/apmodsx" >/dev/null 2>&1 &');
            return;
        } catch (_) { }
    }
    window.location.href = 'https://t.me/apmodsx';
}

function openDonate(e) {
    e.preventDefault();
    if (typeof ksu?.exec === 'function') {
        try {
            ksu.exec('nohup am start -a android.intent.action.VIEW -d "https://donate.dsorak.com/" >/dev/null 2>&1 &');
            return;
        } catch (_) { }
    }
    window.location.href = 'https://donate.dsorak.com/';
}

// =========================================
// Init
// =========================================
async function init() {
    showLoading(true);
    log('Initializing...', 'info');

    try {
        // Root check
        const who = await exec('whoami');
        const root = who.includes('root');
        document.getElementById('rootStatus').textContent = root ? '✓' : '✗';
        document.getElementById('rootStatus').style.color = root ? '#4ade80' : '#f87171';
        if (!root) log(t('noRootDetected'), 'warning');

        // Module check
        const exists = await exec(`test -d "${MODDIR}" && echo ok || echo no`);
        if (exists.includes('ok')) {
            setStatus(true, t('moduleFound'));

            // Config file check
            const cfgExists = await exec(`test -f "${CONFIG_PATH}" && echo ok || echo no`);
            document.getElementById('configStatus').textContent = cfgExists.includes('ok') ? '✓' : '!';
            document.getElementById('configStatus').style.color = cfgExists.includes('ok') ? '#4ade80' : '#fbbf24';

            await loadThemes();
            await loadConfig();
        } else {
            setStatus(false, t('moduleNotFound'));
            document.getElementById('configStatus').textContent = '✗';
            document.getElementById('configStatus').style.color = '#f87171';
        }
    } catch (e) {
        log(`Error: ${e.message}`, 'error');
        document.getElementById('rootStatus').textContent = '✗';
        document.getElementById('rootStatus').style.color = '#f87171';
    } finally {
        showLoading(false);
    }
}

// =========================================
// Load Themes from themes.json
// =========================================
let themeData = [];
let selectedLightTheme = '';
let selectedDarkTheme = '';

async function loadThemes() {
    log('Loading themes...', 'info');
    try {
        const res = await fetch('themes.json', { cache: 'no-store' });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();

        // Deduplicate by filename
        const seen = new Set();
        themeData = data.filter(i => {
            const fn = (i.filename || '').trim();
            if (!fn.endsWith('.zip') || seen.has(fn)) return false;
            seen.add(fn);
            return true;
        }).sort((a, b) => a.filename.localeCompare(b.filename, undefined, { sensitivity: 'base' }));

        availableThemes = themeData.map(t => t.filename);
        document.getElementById('themeCount').textContent = themeData.length;
        populateThemeCards();
        log(`${t('themesFound')}: ${themeData.length}`, 'success');
    } catch (e) {
        log(`${t('loadThemesError')}: ${e.message}`, 'error');
        availableThemes = [];
        themeData = [];
        document.getElementById('themeCount').textContent = '0';
    }
}

function populateThemeCards() {
    const lightGrid = document.getElementById('lightThemeGrid');
    const darkGrid = document.getElementById('darkThemeGrid');
    lightGrid.innerHTML = '';
    darkGrid.innerHTML = '';

    themeData.forEach(theme => {
        lightGrid.appendChild(createThemeCard(theme, 'light'));
        darkGrid.appendChild(createThemeCard(theme, 'dark'));
    });

    // Peek scroll hint: scroll right briefly then back to show more themes exist
    setTimeout(() => peekScroll(lightGrid), 600);
    setTimeout(() => peekScroll(darkGrid), 900);
}

function peekScroll(el) {
    if (!el || el.scrollWidth <= el.clientWidth) return;
    el.scrollTo({ left: 80, behavior: 'smooth' });
    setTimeout(() => el.scrollTo({ left: 0, behavior: 'smooth' }), 500);
}

function createThemeCard(theme, mode) {
    const card = document.createElement('div');
    card.className = 'theme-card';
    card.dataset.filename = theme.filename;
    card.dataset.mode = mode;

    const label = theme.filename.replace('.zip', '');

    if (theme.preview) {
        const img = document.createElement('img');
        img.className = 'theme-card-img';
        img.src = theme.preview;
        img.alt = label;
        img.loading = 'lazy';
        img.onerror = function () {
            this.replaceWith(createPlaceholder());
        };
        card.appendChild(img);
    } else {
        card.appendChild(createPlaceholder());
    }

    const nameEl = document.createElement('div');
    nameEl.className = 'theme-card-name';
    nameEl.textContent = label;
    card.appendChild(nameEl);

    card.addEventListener('click', () => selectThemeCard(theme.filename, mode));
    return card;
}

function createPlaceholder() {
    const ph = document.createElement('div');
    ph.className = 'theme-card-placeholder';
    ph.textContent = '🎨';
    return ph;
}

function selectThemeCard(filename, mode) {
    const gridId = mode === 'light' ? 'lightThemeGrid' : 'darkThemeGrid';
    const labelId = mode === 'light' ? 'lightThemeSelected' : 'darkThemeSelected';

    // Update state
    if (mode === 'light') selectedLightTheme = filename;
    else selectedDarkTheme = filename;

    // Update visual selection
    document.querySelectorAll(`#${gridId} .theme-card`).forEach(c => {
        c.classList.toggle('selected', c.dataset.filename === filename);
    });

    // Update label
    document.getElementById(labelId).textContent = `— ${filename.replace('.zip', '')}`;

    // Scroll selected card into view (horizontal)
    const selected = document.querySelector(`#${gridId} .theme-card.selected`);
    if (selected) selected.scrollIntoView({ behavior: 'smooth', inline: 'nearest', block: 'nearest' });

    log(`${mode === 'light' ? '☀️' : '🌙'} ${filename.replace('.zip', '')}`, 'info');
}

// =========================================
// Read themes directly from system.prop
// =========================================
async function readThemesFromProp() {
    try {
        const raw = await exec(`cat "${CONFIG_PATH}" 2>/dev/null || echo ""`);
        let light = '';
        let dark = '';
        raw.split('\n').forEach(line => {
            const l = line.trim();
            if (l.startsWith('ro.com.google.ime.theme_file=')) {
                light = l.split('=')[1] || '';
            } else if (l.startsWith('ro.com.google.ime.d_theme_file=')) {
                dark = l.split('=')[1] || '';
            }
        });
        return { lightTheme: light.trim(), darkTheme: dark.trim() };
    } catch (e) {
        log(`system.prop read error: ${e.message}`, 'warning');
        return { lightTheme: '', darkTheme: '' };
    }
}

// =========================================
// Load Config from config.json + sync from system.prop
// =========================================
async function loadConfig() {
    let lightTheme = '';
    let darkTheme = '';
    let needsSync = false;

    // 1. Try config.json first
    try {
        const res = await fetch('config.json', { cache: 'no-store' });
        if (res.ok) {
            const cfg = await res.json();
            lightTheme = (cfg.lightTheme || '').trim();
            darkTheme = (cfg.darkTheme || '').trim();
        }
    } catch (_) { }

    // 2. If config.json has empty values, read from system.prop
    if (!lightTheme || !darkTheme) {
        log('Syncing config from system.prop...', 'info');
        const propCfg = await readThemesFromProp();
        if (!lightTheme && propCfg.lightTheme) {
            lightTheme = propCfg.lightTheme;
            needsSync = true;
        }
        if (!darkTheme && propCfg.darkTheme) {
            darkTheme = propCfg.darkTheme;
            needsSync = true;
        }
    }

    // 3. Sync config.json so it persists for next load
    if (needsSync && (lightTheme || darkTheme)) {
        try {
            const configJson = JSON.stringify({ lightTheme, darkTheme });
            await exec(`echo '${configJson}' > "${WEBROOT_PATH}/config.json"`);
            await exec(`chmod 644 "${WEBROOT_PATH}/config.json"`);
            log('Config synced from system.prop', 'success');
        } catch (e) {
            log(`Config sync error: ${e.message}`, 'warning');
        }
    }

    // 4. Pre-select in card grids
    if (lightTheme && availableThemes.includes(lightTheme)) {
        selectThemeCard(lightTheme, 'light');
    }
    if (darkTheme && availableThemes.includes(darkTheme)) {
        selectThemeCard(darkTheme, 'dark');
    }

    showCurrentConfig(lightTheme, darkTheme);
    log(`☀️ ${t('currentLightTheme')} ${lightTheme || t('notConfigured')}`, 'info');
    log(`🌙 ${t('currentDarkTheme')} ${darkTheme || t('notConfigured')}`, 'info');
}

// =========================================
// Apply Themes
// =========================================
async function applyThemes() {
    if (!moduleActive) { showAlert(t('verifyModuleFirst'), 'warning'); return; }

    const lightTheme = selectedLightTheme;
    const darkTheme = selectedDarkTheme;
    if (!lightTheme || !darkTheme) { showAlert(t('selectBothThemes'), 'warning'); return; }

    showLoading(true);
    log(t('applyingThemes'), 'info');

    try {
        // Update system.prop: remove old entries and write new ones
        await exec(`sed -i '/^ro.com.google.ime.theme_file=/d' "${CONFIG_PATH}"`);
        await exec(`sed -i '/^ro.com.google.ime.d_theme_file=/d' "${CONFIG_PATH}"`);
        await exec(`echo "ro.com.google.ime.theme_file=${lightTheme}" >> "${CONFIG_PATH}"`);
        await exec(`echo "ro.com.google.ime.d_theme_file=${darkTheme}" >> "${CONFIG_PATH}"`);
        await exec(`chmod 644 "${CONFIG_PATH}" && chown root:root "${CONFIG_PATH}"`);

        // Update config.json in webroot so it persists for next WebUI load
        const configJson = JSON.stringify({ lightTheme, darkTheme });
        await exec(`echo '${configJson}' > "${WEBROOT_PATH}/config.json"`);
        await exec(`chmod 644 "${WEBROOT_PATH}/config.json"`);

        // Update display
        showCurrentConfig(lightTheme, darkTheme);

        showAlert(t('themesApplied'), 'success');
        log(t('configSaved'), 'success');
        log(`⚠ ${t('restartRequired')}`, 'warning');
    } catch (e) {
        log(`${t('applyError')}: ${e.message}`, 'error');
        showAlert(t('applyError'), 'error');
    } finally {
        showLoading(false);
    }
}

// =========================================
// Boot
// =========================================
document.addEventListener('DOMContentLoaded', () => {
    // Init language
    const sw = document.getElementById('langSwitch');
    const es = document.getElementById('langEs');
    const en = document.getElementById('langEn');
    sw.classList.toggle('en', lang === 'en');
    es.classList.toggle('active', lang === 'es');
    en.classList.toggle('active', lang === 'en');
    applyTranslations();

    log('🚀 Gboard Theme Manager v2.4', 'success');
    setTimeout(init, 400);
});

window.addEventListener('error', e => log(`JS Error: ${e.message}`, 'error'));
window.addEventListener('unhandledrejection', e => log(`Promise error: ${e.reason}`, 'error'));
