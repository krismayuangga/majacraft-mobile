# Backend API: Store Endpoints Implementation

## Context

Mobile app membutuhkan API endpoints untuk halaman detail toko/seniman. Saat ini backend hanya punya `/api/stores/[slug]/owner` yang return `userId` dan `storeName` saja.

Web app mengambil data store langsung dari Prisma server-side di `src/app/toko/[slug]/page.tsx`, tapi mobile app butuh REST API endpoints.

## ⚠️ CRITICAL FIX NEEDED

### Product API Must Include `store.slug`

**PROBLEM:** Currently `/api/products` returns store object WITHOUT `slug` field:

```json
{
  "store": {
    "name": "Test Gallery",
    "province": "DKI JAKARTA",
    "isVerified": false,
    "rating": 0
    // ❌ Missing: "slug" field
  }
}
```

**REQUIRED:** Add `slug` to store selection in ALL product API responses:

```typescript
// In src/app/api/products/route.ts
// Update store select to include:
store: {
  select: {
    name: true,
    slug: true,        // ✅ ADD THIS
    province: true,
    isVerified: true,
    rating: true,
    totalSold: true,   // Optional but recommended
    logoUrl: true,     // Optional but recommended
  }
}
```

**WHY:** Mobile app needs `store.slug` to navigate from product detail → store detail page. Without slug, "Kunjungi Toko" button cannot work.

**AFFECTED ENDPOINTS:**
- `/api/products` (list)
- `/api/products/[slug]` (detail, if exists)
- Any other endpoint that returns product objects

---

## Required Endpoints

### 1. GET /api/stores/[slug]

**Purpose:** Get full store details by slug

**File Location:** `src/app/api/stores/[slug]/route.ts`

**Implementation:**

```typescript
import { NextRequest } from "next/server";
import { ok, err } from "@/lib/response";
import prisma from "@/lib/prisma";

interface Params {
  params: Promise<{ slug: string }>;
}

export async function GET(_req: NextRequest, { params }: Params) {
  const { slug } = await params;

  const store = await prisma.store.findUnique({
    where: {
      slug,
      isActive: true, // Only return active stores
    },
    select: {
      id: true,
      name: true,
      slug: true,
      description: true,
      logoUrl: true,
      bannerUrl: true,
      province: true,
      city: true,
      district: true,
      address: true,
      phone: true,
      rating: true,
      totalSold: true,
      isVerified: true,
      isActive: true,
      createdAt: true,
      user: {
        select: {
          id: true,
          name: true,
          kycStatus: true,
        },
      },
      _count: {
        select: {
          products: true, // Total product count
        },
      },
    },
  });

  if (!store) {
    return err("Toko tidak ditemukan", 404);
  }

  return ok(store);
}
```

**Response Format:**

```json
{
  "success": true,
  "data": {
    "id": "cmrnk0qwk000ikrwnbdg81sqp",
    "name": "ELmojo Antique",
    "slug": "elmojo-antique",
    "description": "Spesialis gentong antik dari Jawa Timur...",
    "logoUrl": "/uploads/logos/elmojo.jpg",
    "bannerUrl": "/uploads/banners/elmojo-banner.jpg",
    "province": "JAWA TIMUR",
    "city": "Kediri",
    "district": "Pare",
    "address": "Jl. Raya Kediri-Pare No. 123",
    "phone": "+6281234567890",
    "rating": 4.8,
    "totalSold": 127,
    "isVerified": true,
    "isActive": true,
    "createdAt": "2026-07-15T10:30:00.000Z",
    "user": {
      "id": "cmrwgcfvg0000krad2q3pqil8",
      "name": "John Doe",
      "kycStatus": "VERIFIED"
    },
    "_count": {
      "products": 45
    }
  }
}
```

---

### 2. GET /api/stores/[slug]/products

**Purpose:** Get products from a specific store with pagination and filters

**File Location:** `src/app/api/stores/[slug]/products/route.ts`

**Implementation:**

```typescript
import { NextRequest } from "next/server";
import { ok, err } from "@/lib/response";
import prisma from "@/lib/prisma";

interface Params {
  params: Promise<{ slug: string }>;
}

export async function GET(req: NextRequest, { params }: Params) {
  const { slug } = await params;
  const { searchParams } = new URL(req.url);

  // Pagination
  const page = parseInt(searchParams.get("page") || "1");
  const limit = parseInt(searchParams.get("limit") || "20");

  // Filters
  const kategori = searchParams.get("kategori") || undefined;
  const search = searchParams.get("search") || undefined;
  const sort = searchParams.get("sort") || "terbaru";

  // Verify store exists and is active
  const store = await prisma.store.findUnique({
    where: { slug, isActive: true },
    select: { id: true },
  });

  if (!store) {
    return err("Toko tidak ditemukan", 404);
  }

  // Build where clause
  const where: any = {
    storeId: store.id,
    isActive: true,
    isModerated: true,
    isSoldOffline: false,
  };

  if (kategori) {
    where.category = { slug: kategori };
  }

  if (search) {
    where.OR = [
      { name: { contains: search, mode: "insensitive" } },
      { description: { contains: search, mode: "insensitive" } },
      { tags: { has: search } },
    ];
  }

  // Build orderBy clause
  let orderBy: any = { createdAt: "desc" };
  switch (sort) {
    case "terlaris":
      orderBy = { soldCount: "desc" };
      break;
    case "harga-asc":
      orderBy = { price: "asc" };
      break;
    case "harga-desc":
      orderBy = { price: "desc" };
      break;
    case "rating":
      orderBy = { rating: "desc" };
      break;
  }

  // Fetch products with pagination
  const [items, total] = await Promise.all([
    prisma.product.findMany({
      where,
      orderBy,
      skip: (page - 1) * limit,
      take: limit,
      include: {
        images: {
          where: { isPrimary: true },
          take: 1,
        },
        category: {
          select: {
            name: true,
            slug: true,
          },
        },
      },
    }),
    prisma.product.count({ where }),
  ]);

  return ok({
    items,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  });
}
```

**Response Format:**

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "cmrxi2771000bkrlygbv3g8l6",
        "storeId": "cmrnk0qwk000ikrwnbdg81sqp",
        "categoryId": "cat-007",
        "name": "Gentong jawa tali air #EL-011",
        "slug": "gentong-jawa-tali-air-el-011",
        "price": 700000,
        "originalPrice": null,
        "rating": 4.8,
        "reviewCount": 12,
        "soldCount": 5,
        "hasCertificate": false,
        "isFeatured": true,
        "images": [
          {
            "id": "img-001",
            "url": "/uploads/products/gentong-el-011.jpg",
            "sortOrder": 0,
            "isPrimary": true
          }
        ],
        "category": {
          "name": "Keramik & Gerabah",
          "slug": "keramik-gerabah"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 45,
      "totalPages": 3
    }
  }
}
```

**Query Parameters Supported:**

- `page` (default: 1)
- `limit` (default: 20)
- `kategori` - filter by category slug
- `search` - search in name, description, tags
- `sort` - terbaru (default) | terlaris | harga-asc | harga-desc | rating

---

## Alternative: Extend Existing /api/products Endpoint

Jika tidak ingin membuat endpoint baru `/api/stores/[slug]/products`, bisa extend endpoint `/api/products` yang sudah ada dengan menambah filter `storeSlug`.

**Modify:** `src/app/api/products/route.ts`

**Add query parameter:**

```typescript
export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  
  // ... existing code ...
  
  const storeSlug = searchParams.get("storeSlug") || undefined;

  // Build where clause
  const where: any = {
    isActive: true,
    isModerated: true,
    isSoldOffline: false,
  };

  // Add store filter
  if (storeSlug) {
    where.store = { slug: storeSlug };
  }

  // ... rest of the code ...
}
```

**Usage:**

```
GET /api/products?storeSlug=elmojo-antique&page=1&limit=20&sort=terbaru
```

---

## Testing

### Test Store Detail Endpoint

```bash
curl https://majacraft.id/api/stores/elmojo-antique
```

Expected: Full store details with product count

### Test Store Products Endpoint

```bash
curl "https://majacraft.id/api/stores/elmojo-antique/products?page=1&limit=20"
```

Expected: Paginated list of products from that store

### Test with Filters

```bash
curl "https://majacraft.id/api/stores/elmojo-antique/products?kategori=keramik-gerabah&sort=terlaris"
```

Expected: Filtered and sorted products

---

## Migration Notes

1. **No database changes required** - all fields already exist
2. **Backwards compatible** - doesn't affect existing endpoints
3. **Follows existing patterns** - uses same response format as other endpoints
4. **Mobile-ready** - designed for mobile app consumption

---

## Priority

**HIGH** - Mobile app cannot implement store detail page without these endpoints.

Current workaround: Mobile app could extract store info from product detail API, but cannot get full store data or filter products by store.

---

## Related Files

- Web implementation: `src/app/toko/[slug]/page.tsx`
- Existing owner endpoint: `src/app/api/stores/[slug]/owner/route.ts`
- Products endpoint: `src/app/api/products/route.ts`
- Product detail: `src/app/api/products/[id]/route.ts`

---

## Questions?

Contact mobile team or reference this document for implementation details.
