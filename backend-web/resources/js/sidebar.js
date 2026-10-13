const KUNCI = 'sidebar-tertutup';

function terapkan(sidebar, tombolBuka, tertutup) {
    sidebar.classList.toggle('mini', tertutup);
    tombolBuka.classList.toggle('hidden', !tertutup);
}

export function inisialisasiSidebar() {
    const sidebar = document.getElementById('sidebar');
    if (!sidebar) return;

    const tombolTutup = document.getElementById('tombol-tutup-sidebar');
    const tombolBuka = document.getElementById('tombol-buka-sidebar');

    let tertutup = false;
    try {
        tertutup = localStorage.getItem(KUNCI) === '1';
    } catch (error) {
        tertutup = false;
    }

    terapkan(sidebar, tombolBuka, tertutup);

    const simpan = (nilai) => {
        try {
            localStorage.setItem(KUNCI, nilai ? '1' : '0');
        } catch (error) {
            /* abaikan bila localStorage tidak tersedia */
        }
    };

    tombolTutup?.addEventListener('click', () => {
        terapkan(sidebar, tombolBuka, true);
        simpan(true);
    });

    tombolBuka?.addEventListener('click', () => {
        terapkan(sidebar, tombolBuka, false);
        simpan(false);
    });
}
