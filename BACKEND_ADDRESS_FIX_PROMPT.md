# Backend Fix: Address API - Tambah Field District & Village

## Problem

Saat ini Address API di backend hanya menyimpan `province` dan `city`. Tapi mobile app butuh juga `district` (kecamatan) dan `village` (kelurahan/desa).

**Yang terjadi sekarang:**
- User di mobile pilih: Provinsi → Kota → Kecamatan → Kelurahan → Save
- Backend cuma simpan: Provinsi & Kota ❌
- District & Village hilang ❌
- Pas user edit, dropdown Kecamatan & Kelurahan kosong ❌
- User terpaksa nulis "PASAR MINGGU, CILANDAK TIMUR" di field alamat lengkap

**Yang diinginkan:**
- Backend simpan SEMUA: province, city, district, village ✅
- Pas fetch address, return semua field ✅
- Pas edit, dropdown terisi otomatis ✅

---

## Fix Yang Perlu Dilakukan

## Fix Yang Perlu Dilakukan

### 1. Update Database Schema

Tambahkan 2 kolom baru di tabel `Address`:
- `district` (String, nullable/optional)
- `village` (String, nullable/optional)

**Kalau pakai Prisma:**
```prisma
model Address {
  id        String   @id @default(cuid())
  userId    String
  label     String   @default("Rumah")
  name      String
  phone     String
  address   String
  city      String
  province  String
  district  String?  // ← TAMBAH INI
  village   String?  // ← TAMBAH INI
  zip       String
  isDefault Boolean  @default(false)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}
```

Lalu run migration:
```bash
npx prisma migrate dev --name add_district_village
```

### 2. Update API Endpoints

Perlu update 4 endpoint:

#### **POST /api/addresses** (Create)
**Request body yang sekarang mobile kirim:**
```json
{
  "label": "Rumah",
  "name": "angga Adrianto",
  "phone": "085280002089",
  "address": "jln Ampera raya no 15",
  "city": "KOTA JAKARTA SELATAN",
  "province": "DKI JAKARTA",
  "district": "PASAR MINGGU",      // ← TERIMA INI
  "village": "CILANDAK TIMUR",     // ← TERIMA INI
  "zip": "12560",
  "isDefault": false
}
```

**Pastikan backend:**
- Accept field `district` dan `village` dari request body
- Save ke database
- Return semua field di response

#### **PATCH /api/addresses/:id** (Update)
- Same as POST, accept `district` dan `village`
- Update ke database

#### **GET /api/addresses** (List)
**Response harus include district & village:**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "label": "Rumah",
      "name": "angga Adrianto",
      "phone": "085280002089",
      "address": "jln Ampera raya no 15",
      "city": "KOTA JAKARTA SELATAN",
      "province": "DKI JAKARTA",
      "district": "PASAR MINGGU",     // ← RETURN INI
      "village": "CILANDAK TIMUR",    // ← RETURN INI
      "zip": "12560",
      "isDefault": true
    }
  ]
}
```

#### **GET /api/addresses/:id** (Get Single)
- Same as list, return `district` dan `village`

---

## Contoh Code (Node.js + Prisma)

```typescript
// POST /api/addresses
const { 
  label, name, phone, address, 
  city, province,
  district,   // ← TAMBAH
  village,    // ← TAMBAH
  zip, isDefault 
} = await req.json();

// Validation tetap sama (province, city, zip required)

const newAddress = await prisma.address.create({
  data: {
    userId: session.user.id,
    label, name, phone, address,
    city, province,
    district,   // ← SIMPAN
    village,    // ← SIMPAN
    zip, isDefault,
  },
});
```

```typescript
// PATCH /api/addresses/[id]
const { 
  label, name, phone, address, 
  city, province,
  district,   // ← TAMBAH
  village,    // ← TAMBAH
  zip, isDefault 
} = await req.json();

const updated = await prisma.address.update({
  where: { id: params.id },
  data: {
    label, name, phone, address,
    city, province,
    district,   // ← UPDATE
    village,    // ← UPDATE
    zip, isDefault,
  },
});
```

---

## Testing

Setelah fix, test:
1. ✅ POST new address dengan district & village → Saved?
2. ✅ GET addresses → district & village returned?
3. ✅ PATCH address → district & village updated?
4. ✅ Old addresses (tanpa district/village) → Masih bisa fetch tanpa error?

---

## Notes

- Field `district` dan `village` **nullable** → Backward compatible dengan data lama
- Address lama tetap bisa dibuka (district & village = null)
- Mobile app sudah siap terima field ini
- Estimasi waktu: ~20 menit

---

**Priority: HIGH** - User tidak bisa edit address dengan benar tanpa fix ini.
