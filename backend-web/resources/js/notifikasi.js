import Swal from 'sweetalert2';
import 'sweetalert2/dist/sweetalert2.min.css';

const dasar = Swal.mixin({
    buttonsStyling: false,
    customClass: {
        popup: 'rounded-2xl shadow-2xl',
        actions: 'gap-2',
        confirmButton:
            'rounded-lg bg-teal-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-500/40',
        cancelButton:
            'rounded-lg bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-200',
    },
});

const toast = (icon, pesan) =>
    dasar.fire({
        toast: true,
        position: 'top-end',
        icon,
        title: pesan,
        showConfirmButton: false,
        timer: 3500,
        timerProgressBar: true,
    });

export const sukses = (pesan) => toast('success', pesan);

export const info = (pesan) => toast('info', pesan);

export const peringatan = (pesan) => toast('warning', pesan);

export const gagal = (pesan, judul = 'Terjadi Kesalahan') =>
    dasar.fire({
        icon: 'error',
        title: judul,
        text: pesan,
        confirmButtonText: 'Mengerti',
    });

export const daftarGagal = (judul, daftar) =>
    dasar.fire({
        icon: 'error',
        title: judul,
        html: `<ul style="margin:0;padding-left:1.1rem;text-align:left">${daftar
            .map((pesan) => `<li>${escapeHtml(pesan)}</li>`)
            .join('')}</ul>`,
        confirmButtonText: 'Mengerti',
    });

export const konfirmasi = ({
    judul = 'Apakah Anda yakin?',
    pesan = '',
    teksYa = 'Ya, lanjutkan',
    teksBatal = 'Batal',
    icon = 'warning',
} = {}) =>
    dasar
        .fire({
            icon,
            title: judul,
            text: pesan,
            showCancelButton: true,
            confirmButtonText: teksYa,
            cancelButtonText: teksBatal,
            reverseButtons: true,
        })
        .then((hasil) => hasil.isConfirmed);

function escapeHtml(teks) {
    const kamus = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' };
    return String(teks).replace(/[&<>"']/g, (karakter) => kamus[karakter]);
}

function tampilkanFlash() {
    const elemen = document.getElementById('flash-notifikasi');
    if (!elemen) return;

    let data = {};
    try {
        data = JSON.parse(elemen.textContent);
    } catch (error) {
        return;
    } finally {
        elemen.remove();
    }

    if (data.success) sukses(data.success);
    if (data.error) gagal(data.error);

    const daftar = data.errors || [];
    if (daftar.length === 1) gagal(daftar[0]);
    else if (daftar.length > 1) daftarGagal('Data belum dapat disimpan', daftar);
}

function pasangKonfirmasiForm() {
    document.querySelectorAll('form[data-konfirmasi]').forEach((form) => {
        form.addEventListener('submit', (event) => {
            if (form.dataset.konfirmasiDiproses === '1') return;

            event.preventDefault();
            konfirmasi({
                judul: form.dataset.konfirmasiJudul || 'Konfirmasi',
                pesan: form.dataset.konfirmasi,
                teksYa: form.dataset.konfirmasiYa || 'Ya, lanjutkan',
                teksBatal: form.dataset.konfirmasiBatal || 'Batal',
            }).then((setuju) => {
                if (!setuju) return;
                form.dataset.konfirmasiDiproses = '1';
                form.requestSubmit ? form.requestSubmit() : form.submit();
            });
        });
    });
}

export function inisialisasiNotifikasi() {
    const jalan = () => {
        tampilkanFlash();
        pasangKonfirmasiForm();
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', jalan);
    } else {
        jalan();
    }
}
