# Backend Fix: Validasi Berat & Dimensi Produk untuk Kalkulasi Ongkir

## Masalah

Produk "Patung Dewa Wisnu Garuda Wisnu Kencana" memiliki spesifikasi fisik:
- **Berat aktual**: 180 kg
- **Dimensi**: 120 × 90 × 65 cm
- **Material**: Batu Andhesit

Saat kalkulasi ongkir via `POST /api/shipping/cost`, API mengembalikan berat **180.000 gram** (benar dari sisi unit), tapi harga yang dihasilkan sangat tidak masuk akal:
- AnterAja ECO: **Rp 7.100** untuk produk 180 kg

Produk 180 kg seharusnya ongkirnya ratusan ribu hingga jutaan rupiah, bukan Rp 7.100.

---

## Kemungkinan Penyebab

### 1. RajaOngkir hanya menghitung hingga batas berat maksimum
RajaOngkir Starter/Basic membatasi kalkulasi hingga **30 kg**. Berat di atas 30 kg mungkin di-cap atau diabaikan, menghasilkan harga untuk berat minimal.

### 2. Berat yang dikirim ke RajaOngkir dalam satuan yang salah
Jika backend mengirim `weight: 180000` (gram) ke RajaOngkir, tapi RajaOngkir mengharapkan dalam **gram** (bukan kg), maka 180.000 gram = 180 kg sudah benar. Tapi ada kemungkinan API menerima dalam gram tetapi ada overflow atau batasan.

Jika backend salah mengirim `weight: 180` (mengira unit adalah kg, padahal RajaOngkir pakai gram), maka dihitung sebagai 180 gram = 0.18 kg, yang akan menghasilkan harga sangat murah.

### 3. Volumetric weight tidak diperhitungkan
Untuk produk besar, kurir menggunakan **volumetric weight** jika lebih besar dari actual weight:
```
Volumetric = (panjang × lebar × tinggi) / 6000
           = (120 × 90 × 65) / 6000
           = 702.000 / 6000
           = 117 kg (volumetric)
```
Actual weight = 180 kg > 117 kg, jadi actual weight yang digunakan. Ini sudah benar.

---

## Yang Perlu Dicek di Backend

### Cek 1: Satuan berat yang dikirim ke RajaOngkir
```typescript
// Di file handler /api/shipping/cost
// Pastikan weight dikirim dalam GRAM ke RajaOngkir
const weightInGram = product.weight; // harus dalam gram, bukan kg

// Jika weight di database dalam gram:
// "Patung Garuda" = 180000 gram (180 kg) ✓ benar
```

Verifikasi: apakah field `weight` di database Prisma menyimpan dalam **gram** atau **kg**?

### Cek 2: Batas maksimum berat di RajaOngkir API
RajaOngkir memiliki batas maksimum berat per paket. Jika produk melebihi batas, tambahkan:
- Warning bahwa produk terlalu berat untuk kurir regular
- Hanya tampilkan kurir cargo (AnterAja BIG, JNE Trucking, dsb)

### Cek 3: Response yang dikembalikan sudah benar
Dari pengujian langsung, API `/api/shipping/cost` mengembalikan:
```json
{
  "weight": 180000,
  "couriers": [
    { "courier_code": "anteraja", "service_code": "ECO", "price": 7100, "etd": "2-4 Hari" },
    ...
  ]
}
```
Harga Rp 7.100 untuk 180 kg sangat tidak masuk akal. Ini mungkin karena RajaOngkir mengembalikan harga untuk berat minimum (karena melebihi batas maksimum kalkulasi).

---

## Yang Perlu Difix di Backend

### Fix 1: Validasi berat maksimum kurir
Tambahkan logika untuk memfilter kurir yang tidak sanggup membawa beban > tertentu:
- Kurir regular (ECO, REG, DOK, ND, SD, ICE) → max ~30-50 kg
- Kurir cargo (BIG, MIC, JNE Cargo, JNT Cargo) → max 100-300 kg
- Produk > 50 kg → tampilkan hanya kurir cargo

```typescript
// Contoh filter di backend sebelum return couriers
const couriers = rawCouriers.filter(c => {
  if (weightKg > 50) {
    // Hanya tampilkan layanan cargo untuk barang berat
    return ['BIG', 'MIC', 'CARGO', 'TRUCKING', 'JTR'].includes(c.service_code);
  }
  return true;
});
```

### Fix 2: Tambahkan catatan berat di response
Tambahkan field `weightKg` dan `isHeavyItem` di response untuk membantu Flutter menampilkan informasi yang sesuai:
```json
{
  "weight": 180000,
  "weightKg": 180,
  "isHeavyItem": true,
  "couriers": [...]
}
```

### Fix 3: Verifikasi unit berat di database produk
Pastikan field `weight` di tabel `Product` menyimpan berat dalam **gram**:
- Produk 180 kg → `weight: 180000` (gram) ✓
- Produk 500 gram → `weight: 500` (gram) ✓

---

## Verifikasi yang Sudah Dilakukan

✅ API `POST /api/shipping/cost` berjalan dan mengembalikan data  
✅ Format response sudah benar: `courier_code`, `courier_name`, `service_code`, `service_name`, `price`, `etd`  
✅ Berat yang dikirim ke RajaOngkir: `180000` gram (180 kg)  
❌ Harga yang dikembalikan tidak realistis untuk produk 180 kg  
❌ Kurir non-cargo (ECO, DOK) muncul untuk produk sangat berat  

---

## Saran Implementasi

Untuk produk kerajinan seni berat seperti patung batu, pertimbangkan:
1. Tambahkan kategori pengiriman "barang berat/cargo" jika berat > 30 kg
2. Tampilkan estimasi biaya pengiriman dengan catatan "Pengiriman diatur khusus dengan seller"
3. Atau sembunyikan ongkir di checkout dan ganti dengan "Biaya pengiriman akan dikonfirmasi seller"
